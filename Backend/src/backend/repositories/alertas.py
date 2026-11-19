from __future__ import annotations

from psycopg import Connection

from backend.db import conexion
from backend.schemas.paneles import Alerta


class AlertaRepository:
    """Una alerta como máximo por barrio, en la tabla `alertas`."""

    def list(self) -> list[Alerta]:
        with conexion() as conn:
            filas = conn.execute(
                "SELECT id, id_barrio, inicio, expira FROM alertas"
            ).fetchall()
        return [Alerta(**fila) for fila in filas]

    def get(self, id_barrio: str, conn: Connection | None = None) -> Alerta | None:
        with conexion(conn) as actual:
            fila = actual.execute(
                "SELECT id, id_barrio, inicio, expira FROM alertas WHERE id_barrio = %s",
                (id_barrio,),
            ).fetchone()
        return Alerta(**fila) if fila else None

    def set(self, alerta: Alerta) -> Alerta:
        """Crea o reemplaza la alerta del barrio (clave única `id_barrio`)."""
        with conexion() as conn:
            fila = conn.execute(
                """
                INSERT INTO alertas (id, id_barrio, inicio, expira)
                VALUES (%s, %s, %s, %s)
                ON CONFLICT (id_barrio) DO UPDATE
                   SET id = EXCLUDED.id,
                       inicio = EXCLUDED.inicio,
                       expira = EXCLUDED.expira
                RETURNING id, id_barrio, inicio, expira
                """,
                (alerta.id, alerta.id_barrio, alerta.inicio, alerta.expira),
            ).fetchone()
        return Alerta(**fila)


alerta_repository = AlertaRepository()
