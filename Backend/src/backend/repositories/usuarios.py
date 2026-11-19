from __future__ import annotations

from psycopg import Connection

from backend.db import conexion
from backend.schemas.usuarios import UsuarioDB

# Columnas en el mismo orden y con los mismos nombres que el modelo Pydantic.
_COLUMNAS = (
    "id, nombre, correo, clave_hash, rol, id_barrio, estado, fecha_registro, institucion"
)


class UsuarioRepository:
    """Usuarios guardados en la tabla `usuarios` de PostgreSQL."""

    def list(self) -> list[UsuarioDB]:
        with conexion() as conn:
            filas = conn.execute(f"SELECT {_COLUMNAS} FROM usuarios").fetchall()
        return [UsuarioDB(**fila) for fila in filas]

    def get(self, id_usuario: str, conn: Connection | None = None) -> UsuarioDB | None:
        with conexion(conn) as actual:
            fila = actual.execute(
                f"SELECT {_COLUMNAS} FROM usuarios WHERE id = %s", (id_usuario,)
            ).fetchone()
        return UsuarioDB(**fila) if fila else None

    def get_by_correo(self, correo: str) -> UsuarioDB | None:
        with conexion() as conn:
            fila = conn.execute(
                f"SELECT {_COLUMNAS} FROM usuarios WHERE lower(correo) = lower(%s)",
                (correo,),
            ).fetchone()
        return UsuarioDB(**fila) if fila else None

    def add(self, usuario: UsuarioDB) -> UsuarioDB:
        with conexion() as conn:
            conn.execute(
                """
                INSERT INTO usuarios
                    (id, nombre, correo, clave_hash, rol, id_barrio, estado,
                     fecha_registro, institucion)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (id) DO NOTHING
                """,
                (
                    usuario.id,
                    usuario.nombre,
                    usuario.correo,
                    usuario.clave_hash,
                    usuario.rol,
                    usuario.id_barrio,
                    usuario.estado,
                    usuario.fecha_registro,
                    usuario.institucion,
                ),
            )
        return usuario

    def update(self, usuario: UsuarioDB) -> UsuarioDB:
        with conexion() as conn:
            conn.execute(
                """
                UPDATE usuarios
                   SET nombre = %s, correo = %s, clave_hash = %s, rol = %s,
                       id_barrio = %s, estado = %s, institucion = %s
                 WHERE id = %s
                """,
                (
                    usuario.nombre,
                    usuario.correo,
                    usuario.clave_hash,
                    usuario.rol,
                    usuario.id_barrio,
                    usuario.estado,
                    usuario.institucion,
                    usuario.id,
                ),
            )
        return usuario

    def delete(self, id_usuario: str) -> bool:
        with conexion() as conn:
            fila = conn.execute(
                "DELETE FROM usuarios WHERE id = %s RETURNING id", (id_usuario,)
            ).fetchone()
        return fila is not None


usuario_repository = UsuarioRepository()
