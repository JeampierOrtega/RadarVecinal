import hashlib
from datetime import UTC, datetime, timedelta
from uuid import uuid4

from backend.core.seguridad import hashear, verificar_clave
from backend.repositories.barrios import BarrioRepository, barrio_repository
from backend.repositories.usuarios import UsuarioRepository, usuario_repository
from backend.schemas.usuarios import (
    Login,
    ModerarUsuarioRequest,
    UsuarioDB,
    UsuarioRegistro,
    UsuarioUpdate,
    Verificacion,
)
from backend.services.exceptions import (
    AccesoDenegadoError,
    ConflictoError,
    NoAutenticadoError,
    NoEncontradoError,
    SolicitudIncorrectaError,
)


class UsuarioService:
    """Reglas de negocio de cuentas: registro, login, verificación y CRUD."""

    def __init__(
        self,
        repository: UsuarioRepository | None = None,
        barrios: BarrioRepository | None = None,
    ) -> None:
        self._repository = repository or usuario_repository
        self._barrios = barrios or barrio_repository

    # --- sesión ---
    def _verificar_sanciones(self, usuario: UsuarioDB) -> UsuarioDB:
        """Aplica bloqueos si el usuario está Baneado o Suspendido (o levanta la suspensión vencida)."""
        if usuario.estado == "Baneado":
            raise AccesoDenegadoError(
                "Tu cuenta ha sido bloqueada permanentemente por infracciones reiteradas"
            )
        if usuario.estado == "Suspendido":
            ahora = datetime.now(UTC)
            hasta = usuario.suspendido_hasta
            if hasta and hasta.tzinfo is None:
                hasta = hasta.replace(tzinfo=UTC)
            if hasta and hasta > ahora:
                raise AccesoDenegadoError(
                    f"Tu cuenta está suspendida temporalmente hasta {hasta.strftime('%d/%m/%Y %H:%M')}."
                )
            # La suspensión venció: se levanta automáticamente volviendo a 'Verificado'
            usuario = self._repository.update(
                usuario.model_copy(
                    update={
                        "estado": "Verificado",
                        "suspendido_hasta": None,
                        "motivo_sancion": None,
                    }
                )
            )
        return usuario

    def login(self, datos: Login) -> UsuarioDB:
        usuario = self._repository.get_by_correo(datos.correo.lower())
        if usuario is None:
            raise NoAutenticadoError("Correo o contraseña incorrectos. Revisa tus credenciales.")
        return self._verificar_sanciones(usuario)

    def usuario_actual(self, id_usuario: str | None) -> UsuarioDB:
        """Identifica al usuario por el encabezado X-Usuario-Id (sesión simplificada)."""
        if not id_usuario:
            raise NoAutenticadoError("Debes iniciar sesión para usar esta función.")
        usuario = self._repository.get(id_usuario)
        if usuario is None:
            raise NoAutenticadoError("Tu sesión ya no es válida. Vuelve a iniciar sesión.")
        return self._verificar_sanciones(usuario)

    # --- CRUD ---
    def registrar(self, datos: UsuarioRegistro) -> UsuarioDB:
        dni = datos.dni.strip()
        if not (len(dni) == 8 and dni.isdigit()):
            raise SolicitudIncorrectaError("El DNI debe tener exactamente 8 dígitos numéricos.")

        if self._barrios.get(datos.id_barrio) is None:
            raise SolicitudIncorrectaError("El barrio seleccionado no existe.")

        if not self._barrios.validar_codigo(datos.id_barrio, datos.codigo_barrio):
            raise SolicitudIncorrectaError(
                "El código de acceso no corresponde al barrio seleccionado o ha expirado"
            )

        if self._repository.get_by_dni(dni) is not None:
            raise ConflictoError("Este DNI ya se encuentra registrado")

        correo = datos.correo.lower()
        if self._repository.get_by_correo(correo) is not None:
            raise ConflictoError(f"Ya existe una cuenta con el correo '{correo}'.")

        usuario = UsuarioDB(
            id=self._repository.siguiente_id("vecino"),
            nombre=datos.nombre,
            dni=dni,
            correo=correo,
            rol="vecino",
            id_barrio=datos.id_barrio,
            estado="Verificado",
            fecha_registro=datetime.now(UTC),
            clave_hash=hashear(datos.clave),
        )
        return self._repository.add(usuario)

    def listar(self, estado: str | None = None) -> list[UsuarioDB]:
        usuarios = self._repository.list()
        if estado:
            usuarios = [u for u in usuarios if u.estado == estado]
        return usuarios

    def obtener(self, id_usuario: str) -> UsuarioDB:
        usuario = self._repository.get(id_usuario)
        if usuario is None:
            raise NoEncontradoError("un usuario", id_usuario)
        return usuario

    def actualizar(self, id_usuario: str, datos: UsuarioUpdate, actor: UsuarioDB) -> UsuarioDB:
        usuario = self.obtener(id_usuario)
        if actor.id != usuario.id and actor.rol != "municipalidad":
            raise AccesoDenegadoError("Solo puedes modificar tu propia cuenta.")
        if usuario.rol == "vecino" and self._barrios.get(datos.id_barrio) is None:
            raise SolicitudIncorrectaError("El barrio seleccionado no existe.")
        cambios = {"nombre": datos.nombre}
        if usuario.rol == "vecino":
            cambios["id_barrio"] = datos.id_barrio
        return self._repository.update(usuario.model_copy(update=cambios))

    def eliminar(self, id_usuario: str) -> None:
        usuario = self.obtener(id_usuario)
        if usuario.rol == "municipalidad":
            raise SolicitudIncorrectaError("No se puede eliminar una cuenta de la Municipalidad.")
        self._repository.delete(id_usuario)

    # --- verificación (la hace la Municipalidad) ---
    def verificar(self, id_usuario: str, datos: Verificacion) -> UsuarioDB:
        usuario = self.obtener(id_usuario)
        if usuario.rol != "vecino" or usuario.estado != "Pendiente":
            raise SolicitudIncorrectaError("La solicitud ya fue revisada.")
        nuevo_estado = "Verificado" if datos.decision == "aprobar" else "Rechazado"
        return self._repository.update(usuario.model_copy(update={"estado": nuevo_estado}))

    # --- strikes y moderación (Municipalidad / sistema) ---
    def registrar_strike(self, id_usuario: str, motivo: str) -> UsuarioDB:
        """Centraliza la aplicación de strikes: al 3er strike aplica baneo automático."""
        usuario = self.obtener(id_usuario)
        nuevos_strikes = usuario.strikes + 1
        cambios: dict[str, object] = {"strikes": nuevos_strikes}
        if nuevos_strikes >= 3:
            cambios["estado"] = "Baneado"
            cambios["motivo_sancion"] = (
                "Ban automático por acumular 3 infracciones (reportes falsos o falsas alarmas)"
            )
            cambios["suspendido_hasta"] = None
        else:
            cambios["motivo_sancion"] = (
                motivo if not usuario.motivo_sancion else f"{usuario.motivo_sancion}; {motivo}"
            )
        return self._repository.update(usuario.model_copy(update=cambios))

    def moderar(self, id_usuario: str, datos: ModerarUsuarioRequest) -> UsuarioDB:
        """Modera un vecino desde la Municipalidad: suspender, banear o reactivar."""
        usuario = self.obtener(id_usuario)
        if usuario.rol == "municipalidad":
            raise SolicitudIncorrectaError("No se puede moderar una cuenta de la Municipalidad.")

        if datos.accion == "suspender":
            dias = datos.dias if datos.dias in (1, 7, 30) else 1
            suspendido_hasta = datetime.now(UTC) + timedelta(days=dias)
            motivo = datos.motivo or f"Suspensión temporal por {dias} día(s)"
            cambios = {
                "estado": "Suspendido",
                "suspendido_hasta": suspendido_hasta,
                "motivo_sancion": motivo,
            }
        elif datos.accion == "banear":
            motivo = datos.motivo or "Bloqueo permanente por moderación de la Municipalidad"
            cambios = {
                "estado": "Baneado",
                "suspendido_hasta": None,
                "motivo_sancion": motivo,
            }
        elif datos.accion == "reactivar":
            cambios = {
                "estado": "Verificado",
                "strikes": 0,
                "suspendido_hasta": None,
                "motivo_sancion": None,
            }
        else:
            raise SolicitudIncorrectaError(f"Acción '{datos.accion}' no válida.")

        return self._repository.update(usuario.model_copy(update=cambios))


usuario_service = UsuarioService()


def registrar_strike(id_usuario: str, motivo: str) -> UsuarioDB:
    return usuario_service.registrar_strike(id_usuario, motivo)
