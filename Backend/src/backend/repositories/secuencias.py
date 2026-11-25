"""Generación de IDs subrogados con secuencias de PostgreSQL.

Los IDs siguen el formato `<prefijo><número>` (v, m, r, a, i, al) y se obtienen con
`nextval`. Es normal que queden huecos; nunca se usa `MAX(id) + 1` ni UUID.
"""

from __future__ import annotations

from psycopg import Connection

from backend.db import conexion


def siguiente_id(prefijo: str, secuencia: str, conn: Connection | None = None) -> str:
    """Consume la secuencia y devuelve el ID con su prefijo.

    La secuencia se pasa como parámetro y se castea a `regclass`, nunca se interpola
    texto en la sentencia.
    """
    with conexion(conn) as actual:
        fila = actual.execute(
            "SELECT %s::text || nextval(%s::regclass)::text AS id",
            (prefijo, secuencia),
        ).fetchone()
    return fila["id"]
