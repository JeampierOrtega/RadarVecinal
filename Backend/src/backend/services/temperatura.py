"""Funciones puras (sin estado) para geografía y 'temperatura' de los barrios.

Es la misma lógica del prototipo de Lovable, más un bono de novedad para que un
barrio reaccione en cuanto entra un reporte nuevo:
    peso de un reporte = gravedad × factor de confirmación × 0.5^(días / 15)
    bono de un reporte = 2 × max(0, 1 - días / 7)   (0 si es falso o archivado)
    temperatura del barrio = suma de los pesos + min(6, suma de los bonos)
"""

from datetime import datetime

from backend.schemas.barrios import Barrio
from backend.schemas.reportes import Reporte, TipoIncidente
from backend.schemas.zonas import NivelTemperatura

# Gravedad base de cada tipo de incidente.
GRAVEDAD: dict[TipoIncidente, int] = {
    "asalto_robo": 5,
    "pandillaje": 3,
    "alcohol_drogas": 3,
    "falta_alumbrado": 2,
    "actividad_sospechosa": 1,
    "otro": 1,
}

# Umbrales de color: verde < 8 <= amarillo < 18 <= naranja <= 30 < rojo
UMBRALES = {"amarillo": 8, "naranja": 18, "rojo": 30}

# Cada 15 días el peso de un reporte se reduce a la mitad.
VIDA_MEDIA_DIAS = 15

# Bono de novedad: +2 al crearse y baja en línea recta hasta 0 a los 7 días.
# El bono total de un barrio tiene un tope de +6 (un barrio en 0 con un solo
# asalto suma 5 + 2 = 7.0 y sigue en verde; hacen falta dos reportes graves).
BONO_NOVEDAD_MAXIMO = 2.0
BONO_NOVEDAD_DIAS = 7
BONO_NOVEDAD_TOPE = 6.0


def punto_en_poligono(lat: float, lng: float, poligono: list[tuple[float, float]]) -> bool:
    """Algoritmo 'ray casting': cuenta cuántas veces un rayo desde el punto cruza el borde."""
    dentro = False
    j = len(poligono) - 1
    for i in range(len(poligono)):
        y1, x1 = poligono[i]
        y2, x2 = poligono[j]
        if (y1 > lat) != (y2 > lat) and lng < (x2 - x1) * (lat - y1) / (y2 - y1) + x1:
            dentro = not dentro
        j = i
    return dentro


def barrio_del_punto(lat: float, lng: float, barrios: list[Barrio]) -> Barrio | None:
    return next((b for b in barrios if punto_en_poligono(lat, lng, b.poligono)), None)


def factor_confirmacion(reporte: Reporte) -> float:
    """0 si es falso/archivado; 1.0 sin confirmaciones y hasta 1.5 con 3 o más."""
    if reporte.estado in ("falso", "archivado"):
        return 0.0
    confirmaciones = min(max(reporte.confirmaciones, 0), 3)
    return 1 + (confirmaciones / 3) * 0.5


def peso_reporte(reporte: Reporte, ahora: datetime) -> float:
    dias = max(0.0, (ahora - reporte.fecha).total_seconds() / 86_400)
    return reporte.gravedad * factor_confirmacion(reporte) * 0.5 ** (dias / VIDA_MEDIA_DIAS)


def bono_novedad(reporte: Reporte, ahora: datetime) -> float:
    """Bono por lo reciente del reporte: +2 al crearse, 0 a los 7 días (lineal)."""
    if reporte.estado in ("falso", "archivado"):
        return 0.0
    dias = max(0.0, (ahora - reporte.fecha).total_seconds() / 86_400)
    return BONO_NOVEDAD_MAXIMO * max(0.0, 1 - dias / BONO_NOVEDAD_DIAS)


def bono_novedad_zona(reportes: list[Reporte], ahora: datetime) -> float:
    """Suma de los bonos del barrio, con el tope de +6."""
    return min(BONO_NOVEDAD_TOPE, sum(bono_novedad(r, ahora) for r in reportes))


def temperatura_zona(reportes: list[Reporte], ahora: datetime) -> float:
    """Pesos actuales de los reportes + bono de novedad (con su tope)."""
    return sum(peso_reporte(r, ahora) for r in reportes) + bono_novedad_zona(reportes, ahora)


def nivel_temperatura(temperatura: float) -> NivelTemperatura:
    if temperatura > UMBRALES["rojo"]:
        return "rojo"
    if temperatura >= UMBRALES["naranja"]:
        return "naranja"
    if temperatura >= UMBRALES["amarillo"]:
        return "amarillo"
    return "verde"
