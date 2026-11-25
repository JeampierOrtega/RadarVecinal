from __future__ import annotations

from psycopg import Connection

from backend.db import conexion
from backend.repositories.secuencias import siguiente_id
from backend.schemas.paneles import Alerta


_SELECT_ALERTAS = """
    SELECT a.id, a.id_barrio, a.inicio, a.expira, a.id_usuario,
           u.nombre AS autor_nombre, u.dni AS autor_dni,
           b.nombre AS nombre_barrio,
           round(extract(epoch FROM (a.expira - now())) / 60.0, 1) AS minutos_restantes
      FROM alertas a
      JOIN barrios b ON b.id = a.id_barrio
      LEFT JOIN usuarios u ON u.id = a.id_usuario
"""


class AlertaRepository:
    """Una alerta como máximo por barrio, en la tabla `alertas`."""

    def siguiente_id(self, conn: Connection | None = None) -> str:
        return siguiente_id("al", "seq_alertas", conn)

    def list(self) -> list[Alerta]:
        with conexion() as conn:
            filas = conn.execute(_SELECT_ALERTAS).fetchall()
        return [Alerta(**fila) for fila in filas]

    def get(self, id_barrio: str, conn: Connection | None = None) -> Alerta | None:
        with conexion(conn) as actual:
            fila = actual.execute(
                f"{_SELECT_ALERTAS} WHERE a.id_barrio = %s",
                (id_barrio,),
            ).fetchone()
        return Alerta(**fila) if fila else None

    def get_por_id(self, id_alerta: str, conn: Connection | None = None) -> Alerta | None:
        with conexion(conn) as actual:
            fila = actual.execute(
                f"{_SELECT_ALERTAS} WHERE a.id = %s",
                (id_alerta,),
            ).fetchone()
        return Alerta(**fila) if fila else None

    def set(self, alerta: Alerta) -> Alerta:
        """Crea o reemplaza la alerta del barrio (clave única `id_barrio`)."""
        with conexion() as conn:
            conn.execute(
                """
                INSERT INTO alertas (id, id_barrio, inicio, expira, id_usuario)
                VALUES (%s, %s, %s, %s, %s)
                ON CONFLICT (id_barrio) DO UPDATE
                   SET id = EXCLUDED.id,
                       inicio = EXCLUDED.inicio,
                       expira = EXCLUDED.expira,
                       id_usuario = EXCLUDED.id_usuario
                """,
                (alerta.id, alerta.id_barrio, alerta.inicio, alerta.expira, alerta.id_usuario),
            )
            fila = conn.execute(
                f"{_SELECT_ALERTAS} WHERE a.id = %s",
                (alerta.id,),
            ).fetchone()
        return Alerta(**fila)

    def delete(self, id_alerta: str) -> bool:
        with conexion() as conn:
            fila = conn.execute(
                "DELETE FROM alertas WHERE id = %s RETURNING id", (id_alerta,)
            ).fetchone()
        return fila is not None


alerta_repository = AlertaRepository()
