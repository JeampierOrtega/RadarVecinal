from datetime import UTC, datetime, timedelta
from uuid import uuid4

from backend.repositories.acciones import accion_repository
from backend.repositories.barrios import BarrioRepository, barrio_repository
from backend.repositories.reportes import ReporteRepository, reporte_repository
from backend.schemas.reportes import (
    ModeracionReporte,
    Reporte,
    ReporteCreate,
    ReporteDetalle,
    ReporteUpdate,
    Voto,
)
from backend.schemas.usuarios import ModerarUsuarioRequest, UsuarioDB
from backend.services.exceptions import (
    AccesoDenegadoError,
    ConflictoError,
    LimiteExcedidoError,
    NoEncontradoError,
    SolicitudIncorrectaError,
)
from backend.services.temperatura import GRAVEDAD, barrio_del_punto
from backend.services.usuarios import usuario_service

# Ventana para considerar que dos envíos del mismo vecino son el mismo reporte repetido.
MINUTOS_DUPLICADO = 10


def _normalizar(texto: str) -> str:
    """Minúsculas y espacios simples: 'Robo  en la esquina' == 'robo en la esquina'."""
    return " ".join(texto.lower().split())


class ReporteService:
    """Reglas de negocio de los reportes ciudadanos."""

    def __init__(
        self,
        repository: ReporteRepository | None = None,
        barrios: BarrioRepository | None = None,
    ) -> None:
        self._repository = repository or reporte_repository
        self._barrios = barrios or barrio_repository

    # --- ayudas internas ---
    def _buscar(self, id_reporte: str) -> Reporte:
        reporte = self._repository.get(id_reporte)
        if reporte is None:
            raise NoEncontradoError("un reporte", id_reporte)
        return reporte

    def _propio(self, id_reporte: str, usuario: UsuarioDB) -> Reporte:
        reporte = self._buscar(id_reporte)
        if reporte.id_usuario != usuario.id:
            raise AccesoDenegadoError("Solo puedes modificar tus propios reportes.")
        return reporte

    def _barrio_id(self, lat: float, lng: float) -> str:
        barrio = barrio_del_punto(lat, lng, self._barrios.list())
        if barrio is None:
            raise SolicitudIncorrectaError("El punto debe estar dentro de un barrio del mapa.")
        return barrio.id

    # --- consultas ---
    def listar(self, tipo: str | None = None, dias: int | None = None) -> list[Reporte]:
        """Reportes públicos (no archivados ni falsos), anónimos hacia los vecinos."""
        desde = datetime.now(UTC) - timedelta(days=dias) if dias else None
        resultado = []
        for r in self._repository.list():
            if r.estado in ("archivado", "falso"):
                continue
            if desde is not None and r.fecha < desde:
                continue
            if tipo not in (None, "todos") and r.tipo != tipo:
                continue
            resultado.append(
                r.model_copy(
                    update={
                        "autor_nombre": None,
                        "autor_dni": None,
                        "autor_strikes": None,
                    }
                )
            )
        return sorted(resultado, key=lambda r: r.fecha, reverse=True)

    def listar_para_municipalidad(self) -> list[Reporte]:
        """Reportes para el panel de la Municipalidad: incluye datos del autor y prioriza sospechosos."""
        todos = [r for r in self._repository.list() if r.estado != "archivado"]

        def criterio_prioridad(r: Reporte):
            tiene_sospecha = 1 if (r.denuncias > 0 or r.incorrectos > 0) else 0
            return (tiene_sospecha, r.denuncias + r.incorrectos, r.fecha)

        return sorted(todos, key=criterio_prioridad, reverse=True)

    def mios(self, usuario: UsuarioDB) -> list[Reporte]:
        propios = [r for r in self._repository.list() if r.id_usuario == usuario.id]
        return sorted(propios, key=lambda r: r.fecha, reverse=True)

    def detalle(self, id_reporte: str, usuario: UsuarioDB) -> ReporteDetalle:
        reporte = self._buscar(id_reporte)
        votos = self._repository.votos_de(id_reporte)
        denuncias = self._repository.denuncias_de(id_reporte)
        acciones = sorted(
            (a for a in accion_repository.list() if a.id_reporte == id_reporte),
            key=lambda a: a.fecha,
        )
        return ReporteDetalle(
            **reporte.model_dump(exclude={"denuncias", "incorrectos"}),
            propio=reporte.id_usuario == usuario.id,
            mi_voto=votos.get(usuario.id),
            denunciado=usuario.id in denuncias,
            incorrectos=sum(1 for v in votos.values() if v == "incorrecto"),
            denuncias=len(denuncias),
            acciones=acciones,
        )

    # --- CRUD ---
    def crear(self, datos: ReporteCreate, usuario: UsuarioDB) -> Reporte:
        self._revisar_antispam_y_duplicado(datos, usuario)
        id_barrio = self._barrio_id(datos.lat, datos.lng)
        reporte = Reporte(
            **datos.model_dump(),
            id=f"r_{uuid4().hex[:8]}",
            id_usuario=usuario.id,  # el autor sale de la sesión, nunca del cliente
            gravedad=GRAVEDAD[datos.tipo],
            id_barrio=id_barrio,
            fecha=datetime.now(UTC),
            estado="activo",
            confirmaciones=0,
        )
        return self._repository.add(reporte)

    def _revisar_antispam_y_duplicado(self, datos: ReporteCreate, usuario: UsuarioDB) -> None:
        """Control anti-spam: máx 3 reportes en 60m, mín 3m entre reportes, ni descripción idéntica."""
        ahora = datetime.now(UTC)
        hace_60m = ahora - timedelta(minutes=60)
        hace_3m = ahora - timedelta(minutes=3)
        mensaje_limite = (
            "Has alcanzado el límite temporal de reportes. Espera unos minutos antes de publicar otro"
        )

        reportes_usuario = [
            r for r in self._repository.list()
            if r.id_usuario == usuario.id and r.estado != "archivado"
        ]

        # 1. Máximo 3 reportes en los últimos 60 minutos
        recientes_60m = [r for r in reportes_usuario if r.fecha >= hace_60m]
        if len(recientes_60m) >= 3:
            raise LimiteExcedidoError(mensaje_limite)

        # 2. No puede publicar dos reportes en menos de 3 minutos
        recientes_3m = [r for r in reportes_usuario if r.fecha >= hace_3m]
        if recientes_3m:
            raise LimiteExcedidoError(mensaje_limite)

        # 3. No puede duplicar la misma descripción
        desc_nueva = _normalizar(datos.descripcion)
        for r in reportes_usuario:
            if _normalizar(r.descripcion) == desc_nueva:
                raise LimiteExcedidoError(mensaje_limite)

    def actualizar(self, id_reporte: str, datos: ReporteUpdate, usuario: UsuarioDB) -> Reporte:
        reporte = self._propio(id_reporte, usuario)
        id_barrio = self._barrio_id(datos.lat, datos.lng)
        actualizado = reporte.model_copy(
            update={**datos.model_dump(), "id_barrio": id_barrio, "gravedad": GRAVEDAD[datos.tipo]}
        )
        return self._repository.update(actualizado)

    def eliminar(self, id_reporte: str, usuario: UsuarioDB) -> None:
        self._propio(id_reporte, usuario)
        self._repository.delete(id_reporte)

    # --- interacción entre vecinos ---
    def votar(self, id_reporte: str, datos: Voto, usuario: UsuarioDB) -> Reporte:
        reporte = self._buscar(id_reporte)
        if reporte.id_usuario == usuario.id:
            raise AccesoDenegadoError("No puedes valorar tu propio reporte.")
        if reporte.estado in ("falso", "archivado"):
            raise SolicitudIncorrectaError("Este reporte ya fue descartado por la Municipalidad.")
        # El repository guarda el voto y recalcula confirmaciones/estado en una transacción.
        actualizado = self._repository.votar(id_reporte, usuario.id, datos.voto)
        if actualizado is None:
            raise ConflictoError("Ya registraste tu valoración de este reporte.")
        # Una valoración negativa NO declara falso el reporte: lo revisa la Municipalidad.
        return actualizado

    def denunciar(self, id_reporte: str, usuario: UsuarioDB) -> None:
        self._buscar(id_reporte)
        if not self._repository.denunciar(id_reporte, usuario.id):
            raise ConflictoError("Ya denunciaste este reporte.")

    # --- moderación (Municipalidad) ---
    def moderar(self, id_reporte: str, datos: ModeracionReporte) -> Reporte:
        reporte = self._buscar(id_reporte)
        return self._repository.update(reporte.model_copy(update={"estado": datos.estado}))

    def moderar_reporte(self, id_reporte: str, accion: str) -> dict[str, str]:
        """Modera un reporte: 'marcar_falso' (+1 strike) o 'purgar_spam' (purga y ban inmediato)."""
        reporte = self._buscar(id_reporte)
        if accion == "marcar_falso":
            self._repository.update(reporte.model_copy(update={"estado": "falso"}))
            usuario_service.registrar_strike(
                reporte.id_usuario,
                f"Reporte falso #{id_reporte}: {reporte.descripcion[:60]}",
            )
            return {"detail": "Reporte marcado como falso y se aplicó +1 strike al autor."}
        elif accion == "purgar_spam":
            self._repository.purgar_por_usuario(reporte.id_usuario)
            usuario_service.moderar(
                reporte.id_usuario,
                ModerarUsuarioRequest(
                    accion="banear",
                    motivo=f"Ban inmediato por spam masivo detectado a partir del reporte #{id_reporte}",
                ),
            )
            return {"detail": "Reportes del autor purgados y usuario baneado permanentemente."}
        else:
            raise SolicitudIncorrectaError("Acción de moderación no reconocida.")


reporte_service = ReporteService()
