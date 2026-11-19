from __future__ import annotations

from psycopg import Connection

from backend.db import conexion
from backend.schemas.acciones import Accion

# Columnas en el mismo orden y con los mismos nombres que el modelo Pydantic.
_COLUMNAS = """
    id, id_barrio, id_autoridad, institucion, tipo, titulo, descripcion, fecha,
    estado, fotos, id_reporte, fecha_registro, temperatura_al_completar
"""


class AccionRepository:
    """Acciones municipales y noticias leídas, guardadas en PostgreSQL."""

    def list(self) -> list[Accion]:
        with conexion() as conn:
            filas = conn.execute(f"SELECT {_COLUMNAS} FROM acciones").fetchall()
        return [Accion(**fila) for fila in filas]

    def get(self, id_accion: str, conn: Connection | None = None) -> Accion | None:
        with conexion(conn) as actual:
            fila = actual.execute(
                f"SELECT {_COLUMNAS} FROM acciones WHERE id = %s", (id_accion,)
            ).fetchone()
        return Accion(**fila) if fila else None

    def add(self, accion: Accion) -> Accion:
        with conexion() as conn:
            conn.execute(
                """
                INSERT INTO acciones
                    (id, id_barrio, id_autoridad, institucion, tipo, titulo,
                     descripcion, fecha, estado, fotos, id_reporte, fecha_registro,
                     temperatura_al_completar)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (id) DO NOTHING
                """,
                (
                    accion.id,
                    accion.id_barrio,
                    accion.id_autoridad,
                    accion.institucion,
                    accion.tipo,
                    accion.titulo,
                    accion.descripcion,
                    accion.fecha,
                    accion.estado,
                    accion.fotos,
                    accion.id_reporte,
                    accion.fecha_registro,
                    accion.temperatura_al_completar,
                ),
            )
        return accion

    def update(self, accion: Accion) -> Accion:
        with conexion() as conn:
            conn.execute(
                """
                UPDATE acciones
                   SET id_barrio = %s, institucion = %s, tipo = %s, titulo = %s,
                       descripcion = %s, fecha = %s, estado = %s, fotos = %s,
                       id_reporte = %s, temperatura_al_completar = %s
                 WHERE id = %s
                """,
                (
                    accion.id_barrio,
                    accion.institucion,
                    accion.tipo,
                    accion.titulo,
                    accion.descripcion,
                    accion.fecha,
                    accion.estado,
                    accion.fotos,
                    accion.id_reporte,
                    accion.temperatura_al_completar,
                    accion.id,
                ),
            )
        return accion

    def delete(self, id_accion: str) -> bool:
        # Las noticias leídas asociadas se borran en cascada.
        with conexion() as conn:
            fila = conn.execute(
                "DELETE FROM acciones WHERE id = %s RETURNING id", (id_accion,)
            ).fetchone()
        return fila is not None

    # --- noticias leídas ---
    def leidas_de(self, id_usuario: str) -> set[str]:
        with conexion() as conn:
            filas = conn.execute(
                "SELECT id_accion FROM noticias_leidas WHERE id_usuario = %s",
                (id_usuario,),
            ).fetchall()
        return {fila["id_accion"] for fila in filas}

    def marcar_leidas(self, id_usuario: str, ids_acciones: list[str]) -> None:
        """Marca como leídas varias noticias en una sola sentencia (idempotente)."""
        if not ids_acciones:
            return
        with conexion() as conn:
            conn.execute(
                """
                INSERT INTO noticias_leidas (id_usuario, id_accion)
                SELECT %s, id FROM acciones WHERE id = ANY(%s)
                ON CONFLICT DO NOTHING
                """,
                (id_usuario, ids_acciones),
            )


accion_repository = AccionRepository()
