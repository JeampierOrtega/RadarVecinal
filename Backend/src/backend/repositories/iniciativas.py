from __future__ import annotations

from psycopg import Connection

from backend.db import conexion
from backend.schemas.iniciativas import Iniciativa

# `participantes` se cuenta desde la tabla puente, nunca se guarda como número.
_SELECT = """
    SELECT i.id, i.id_barrio, i.id_creador, i.titulo, i.descripcion, i.meta,
           i.estado, i.temperatura_al_cumplir,
           (SELECT count(*) FROM iniciativa_participantes p
             WHERE p.id_iniciativa = i.id) AS participantes
      FROM iniciativas i
"""


class IniciativaRepository:
    """Iniciativas vecinales y sus participantes, guardados en PostgreSQL."""

    def list(self) -> list[Iniciativa]:
        with conexion() as conn:
            filas = conn.execute(_SELECT).fetchall()
        return [Iniciativa(**fila) for fila in filas]

    def get(self, id_iniciativa: str, conn: Connection | None = None) -> Iniciativa | None:
        with conexion(conn) as actual:
            fila = actual.execute(
                f"{_SELECT} WHERE i.id = %s", (id_iniciativa,)
            ).fetchone()
        return Iniciativa(**fila) if fila else None

    def add(self, iniciativa: Iniciativa) -> Iniciativa:
        with conexion() as conn:
            conn.execute(
                """
                INSERT INTO iniciativas
                    (id, id_barrio, id_creador, titulo, descripcion, meta, estado,
                     temperatura_al_cumplir)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (id) DO NOTHING
                """,
                (
                    iniciativa.id,
                    iniciativa.id_barrio,
                    iniciativa.id_creador,
                    iniciativa.titulo,
                    iniciativa.descripcion,
                    iniciativa.meta,
                    iniciativa.estado,
                    iniciativa.temperatura_al_cumplir,
                ),
            )
        return iniciativa

    def update(self, iniciativa: Iniciativa) -> Iniciativa:
        with conexion() as conn:
            conn.execute(
                """
                UPDATE iniciativas
                   SET id_barrio = %s, titulo = %s, descripcion = %s, meta = %s,
                       estado = %s, temperatura_al_cumplir = %s
                 WHERE id = %s
                """,
                (
                    iniciativa.id_barrio,
                    iniciativa.titulo,
                    iniciativa.descripcion,
                    iniciativa.meta,
                    iniciativa.estado,
                    iniciativa.temperatura_al_cumplir,
                    iniciativa.id,
                ),
            )
        return iniciativa

    def delete(self, id_iniciativa: str) -> bool:
        # Los participantes se borran en cascada.
        with conexion() as conn:
            fila = conn.execute(
                "DELETE FROM iniciativas WHERE id = %s RETURNING id", (id_iniciativa,)
            ).fetchone()
        return fila is not None

    # --- participantes ---
    def participantes_de(self, id_iniciativa: str) -> set[str]:
        with conexion() as conn:
            filas = conn.execute(
                "SELECT id_usuario FROM iniciativa_participantes WHERE id_iniciativa = %s",
                (id_iniciativa,),
            ).fetchall()
        return {fila["id_usuario"] for fila in filas}

    def sumarse(self, id_iniciativa: str, id_usuario: str) -> Iniciativa | None:
        """Registra al participante y devuelve la iniciativa con el conteo actualizado.

        Inserción y recuento van en la misma transacción. None si ya participaba.
        """
        with conexion() as conn:
            insertado = conn.execute(
                """
                INSERT INTO iniciativa_participantes (id_iniciativa, id_usuario)
                VALUES (%s, %s)
                ON CONFLICT (id_iniciativa, id_usuario) DO NOTHING
                RETURNING id_usuario
                """,
                (id_iniciativa, id_usuario),
            ).fetchone()
            if insertado is None:
                return None
            fila = conn.execute(f"{_SELECT} WHERE i.id = %s", (id_iniciativa,)).fetchone()
        return Iniciativa(**fila)


iniciativa_repository = IniciativaRepository()
