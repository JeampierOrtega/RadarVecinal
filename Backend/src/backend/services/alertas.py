from datetime import UTC, datetime, timedelta

from backend.repositories.alertas import AlertaRepository, alerta_repository
from backend.schemas.paneles import Alerta
from backend.schemas.usuarios import UsuarioDB
from backend.services.exceptions import NoEncontradoError, SolicitudIncorrectaError
from backend.services.usuarios import usuario_service

DURACION_ALERTA = timedelta(minutes=30)


class AlertaService:
    """Alertas de barrio: un vecino activa una y el barrio queda 'EN ALERTA' 30 minutos."""

    def __init__(self, repository: AlertaRepository | None = None) -> None:
        self._repository = repository or alerta_repository

    def activas(self) -> list[Alerta]:
        ahora = datetime.now(UTC)
        return [a for a in self._repository.list() if a.expira > ahora]

    def activar(self, usuario: UsuarioDB) -> Alerta:
        if usuario.id_barrio is None:
            raise SolicitudIncorrectaError("No tienes un barrio asignado.")
        ahora = datetime.now(UTC)
        previa = self._repository.get(usuario.id_barrio)
        if previa is not None and previa.expira > ahora:
            return previa  # una alerta activa nunca se extiende: dura siempre 30 minutos
        alerta = Alerta(
            id=self._repository.siguiente_id(),
            id_barrio=usuario.id_barrio,
            inicio=ahora,
            expira=ahora + DURACION_ALERTA,
            id_usuario=usuario.id,
        )
        return self._repository.set(alerta)

    def cancelar(self, id_alerta: str, motivo: str) -> dict[str, str]:
        alerta = self._repository.get_por_id(id_alerta)
        if alerta is None:
            raise NoEncontradoError("una alerta", id_alerta)

        if motivo == "falsa_alarma" and alerta.id_usuario:
            usuario_service.registrar_strike(
                alerta.id_usuario,
                f"Falsa alarma de pánico activada en barrio {alerta.nombre_barrio or alerta.id_barrio}",
            )
            mensaje = "Alerta cancelada por falsa alarma (+1 strike aplicado al autor)."
        else:
            mensaje = "Alerta atendida con éxito."

        self._repository.delete(id_alerta)
        return {"detail": mensaje}


alerta_service = AlertaService()
