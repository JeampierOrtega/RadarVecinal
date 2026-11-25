from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field

from backend.schemas.acciones import Accion
from backend.schemas.reportes import ReportePublico
from backend.schemas.usuarios import Usuario
from backend.schemas.zonas import PuntoCaliente, ZonaResumen


class Alerta(BaseModel):
    """Alerta de barrio: dura 30 minutos desde su inicio."""

    id: str
    id_barrio: str
    inicio: datetime
    expira: datetime
    id_usuario: str | None = None
    autor_nombre: str | None = None
    autor_dni: str | None = None
    nombre_barrio: str | None = None
    minutos_restantes: float | None = None


class CancelarAlertaRequest(BaseModel):
    motivo: Literal["atendida", "falsa_alarma"]


class PanelMunicipal(BaseModel):
    """Todo lo que necesita la pantalla de la Municipalidad."""

    zonas: list[ZonaResumen]
    criticos: list[ZonaResumen]
    acciones: list[Accion]
    propias: list[Accion]
    pendientes: list[Usuario] = Field(default_factory=list)
    vecinos: list[Usuario] = Field(default_factory=list)
    alertas: list[Alerta] = Field(default_factory=list)
    reportes: list[ReportePublico]
    puntos: list[PuntoCaliente]


class MiBarrio(BaseModel):
    """Todo lo que necesita la pantalla 'Mi barrio' del vecino."""

    zona: ZonaResumen | None
    reportes: list[ReportePublico]
    noticias: list[Accion]


class NoticiasNuevas(BaseModel):
    nuevas: bool


class NoticiasLeidas(BaseModel):
    ids: list[str]
