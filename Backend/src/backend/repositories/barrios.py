from __future__ import annotations

from psycopg import Connection

from backend.db import conexion
from backend.schemas.barrios import Barrio


def _a_barrio(fila: dict) -> Barrio:
    """JSONB `[[lat, lng], ...]` -> `list[tuple[float, float]]`."""
    return Barrio(
        id=fila["id"],
        nombre=fila["nombre"],
        poligono=[(float(lat), float(lng)) for lat, lng in fila["poligono"]],
    )


class BarrioRepository:
    """Catálogo de barrios de la tabla `barrios` (solo lectura)."""

    def list(self, conn: Connection | None = None) -> list[Barrio]:
        with conexion(conn) as actual:
            filas = actual.execute(
                "SELECT id, nombre, poligono FROM barrios ORDER BY length(id), id"
            ).fetchall()
        return [_a_barrio(fila) for fila in filas]

    def get(self, id_barrio: str, conn: Connection | None = None) -> Barrio | None:
        with conexion(conn) as actual:
            fila = actual.execute(
                "SELECT id, nombre, poligono FROM barrios WHERE id = %s", (id_barrio,)
            ).fetchone()
        return _a_barrio(fila) if fila else None


barrio_repository = BarrioRepository()
