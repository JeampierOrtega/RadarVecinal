from __future__ import annotations

from psycopg import Connection

from backend.db import conexion
from backend.repositories.secuencias import siguiente_id
from backend.schemas.reportes import Reporte

# `confirmaciones` y `denuncias` no son columnas: se cuentan desde sus tablas.
# Un reporte "confirmado" a mano por la Municipalidad conserva su estado, pero los
# conteos siempre reflejan los votos y denuncias reales.
_SELECT = """
    SELECT r.id, r.lat, r.lng, r.id_barrio, r.tipo, r.gravedad, r.descripcion,
           r.fecha, r.estado, r.id_usuario,
           (SELECT count(*) FROM votos_reporte v
             WHERE v.id_reporte = r.id AND v.voto = 'confirmo') AS confirmaciones,
           (SELECT count(*) FROM denuncias_reporte d
             WHERE d.id_reporte = r.id) AS denuncias
      FROM reportes r
"""


def _a_reporte(fila: dict) -> Reporte:
    return Reporte(**fila)


class ReporteRepository:
    """Reportes, votos y denuncias guardados en PostgreSQL."""

    def siguiente_id(self, conn: Connection | None = None) -> str:
        return siguiente_id("r", "seq_reportes", conn)

    # --- reportes ---
    def list(self) -> list[Reporte]:
        with conexion() as conn:
            filas = conn.execute(_SELECT).fetchall()
        return [_a_reporte(fila) for fila in filas]

    def get(self, id_reporte: str, conn: Connection | None = None) -> Reporte | None:
        with conexion(conn) as actual:
            fila = actual.execute(f"{_SELECT} WHERE r.id = %s", (id_reporte,)).fetchone()
        return _a_reporte(fila) if fila else None

    def add(self, reporte: Reporte) -> Reporte:
        with conexion() as conn:
            conn.execute(
                """
                INSERT INTO reportes
                    (id, id_usuario, id_barrio, lat, lng, tipo, gravedad,
                     descripcion, fecha, estado)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (id) DO NOTHING
                """,
                (
                    reporte.id,
                    reporte.id_usuario,
                    reporte.id_barrio,
                    reporte.lat,
                    reporte.lng,
                    reporte.tipo,
                    reporte.gravedad,
                    reporte.descripcion,
                    reporte.fecha,
                    reporte.estado,
                ),
            )
            fila = conn.execute(f"{_SELECT} WHERE r.id = %s", (reporte.id,)).fetchone()
        return _a_reporte(fila)

    def update(self, reporte: Reporte) -> Reporte:
        with conexion() as conn:
            conn.execute(
                """
                UPDATE reportes
                   SET lat = %s, lng = %s, id_barrio = %s, tipo = %s,
                       gravedad = %s, descripcion = %s, estado = %s
                 WHERE id = %s
                """,
                (
                    reporte.lat,
                    reporte.lng,
                    reporte.id_barrio,
                    reporte.tipo,
                    reporte.gravedad,
                    reporte.descripcion,
                    reporte.estado,
                    reporte.id,
                ),
            )
            fila = conn.execute(f"{_SELECT} WHERE r.id = %s", (reporte.id,)).fetchone()
        return _a_reporte(fila)

    def delete(self, id_reporte: str) -> bool:
        # Los votos y denuncias se borran en cascada (ON DELETE CASCADE).
        with conexion() as conn:
            fila = conn.execute(
                "DELETE FROM reportes WHERE id = %s RETURNING id", (id_reporte,)
            ).fetchone()
        return fila is not None

    # --- votos ---
    def votos_de(self, id_reporte: str) -> dict[str, str]:
        with conexion() as conn:
            filas = conn.execute(
                "SELECT id_usuario, voto FROM votos_reporte WHERE id_reporte = %s",
                (id_reporte,),
            ).fetchall()
        return {fila["id_usuario"]: fila["voto"] for fila in filas}

    def votar(self, id_reporte: str, id_usuario: str, voto: str) -> Reporte | None:
        """Guarda el voto, recalcula confirmaciones y actualiza el estado.

        Todo ocurre en una sola transacción. Devuelve None si el vecino ya había votado.
        """
        with conexion() as conn:
            insertado = conn.execute(
                """
                INSERT INTO votos_reporte (id_reporte, id_usuario, voto)
                VALUES (%s, %s, %s)
                ON CONFLICT (id_reporte, id_usuario) DO NOTHING
                RETURNING id_usuario
                """,
                (id_reporte, id_usuario, voto),
            ).fetchone()
            if insertado is None:
                return None
            if voto == "confirmo":
                fila = conn.execute(
                    """
                    SELECT count(*) AS confirmaciones
                      FROM votos_reporte
                     WHERE id_reporte = %s AND voto = 'confirmo'
                    """,
                    (id_reporte,),
                ).fetchone()
                if fila["confirmaciones"] >= 3:
                    conn.execute(
                        "UPDATE reportes SET estado = 'confirmado' "
                        "WHERE id = %s AND estado = 'activo'",
                        (id_reporte,),
                    )
            fila = conn.execute(f"{_SELECT} WHERE r.id = %s", (id_reporte,)).fetchone()
        return _a_reporte(fila)

    # --- denuncias ---
    def denuncias_de(self, id_reporte: str) -> set[str]:
        with conexion() as conn:
            filas = conn.execute(
                "SELECT id_usuario FROM denuncias_reporte WHERE id_reporte = %s",
                (id_reporte,),
            ).fetchall()
        return {fila["id_usuario"] for fila in filas}

    def denunciar(self, id_reporte: str, id_usuario: str) -> bool:
        """Registra una denuncia; False si el vecino ya había denunciado el reporte."""
        with conexion() as conn:
            fila = conn.execute(
                """
                INSERT INTO denuncias_reporte (id_reporte, id_usuario)
                VALUES (%s, %s)
                ON CONFLICT (id_reporte, id_usuario) DO NOTHING
                RETURNING id_usuario
                """,
                (id_reporte, id_usuario),
            ).fetchone()
        return fila is not None


reporte_repository = ReporteRepository()
