"""Conexión a PostgreSQL (psycopg 3) con un pool compartido por toda la API.

Las credenciales se leen de `Backend/.env` (ver `.env.example`). El pool se abre al
arrancar la aplicación y se cierra al apagarla (lifespan de `main.py`).
"""

import logging
import os
from collections.abc import Iterator
from contextlib import contextmanager
from pathlib import Path

from dotenv import load_dotenv
from psycopg import Connection
from psycopg.conninfo import make_conninfo
from psycopg.rows import dict_row
from psycopg_pool import ConnectionPool

logger = logging.getLogger("radar_vecinal")

# `Backend/src/backend/db.py` -> `Backend/.env`
RUTA_ENV = Path(__file__).resolve().parents[2] / ".env"
load_dotenv(RUTA_ENV)


def _conninfo() -> str:
    """Arma la cadena de conexión a partir de las variables del `.env`."""
    faltantes = [
        nombre
        for nombre in ("DB_HOST", "DB_NAME", "DB_USER", "DB_PASSWORD")
        if not os.getenv(nombre)
    ]
    if faltantes:
        raise RuntimeError(
            f"Faltan variables de conexión en {RUTA_ENV}: {', '.join(faltantes)}. "
            "Copia Backend/.env.example a Backend/.env y completa los valores."
        )
    return make_conninfo(
        host=os.environ["DB_HOST"],
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        port=os.getenv("DB_PORT", "5432"),
    )


# El pool queda cerrado hasta que el lifespan lo abre: importar el módulo no conecta.
pool = ConnectionPool(
    conninfo=_conninfo(),
    min_size=1,
    max_size=10,
    open=False,
    # Cada fila se devuelve como un diccionario {"columna": valor}.
    kwargs={"row_factory": dict_row},
)


def abrir_pool() -> None:
    """Abre el pool y espera a que la base de datos responda."""
    try:
        pool.open(wait=True, timeout=10.0)
    except Exception as exc:  # psycopg_pool lanza PoolTimeout si no hay conexión
        raise RuntimeError(
            "No se pudo conectar a PostgreSQL. Verifica que el contenedor de Docker "
            f"esté encendido y los datos de conexión de {RUTA_ENV}."
        ) from exc
    logger.info("Pool de PostgreSQL abierto (%s)", os.getenv("DB_HOST"))


def cerrar_pool() -> None:
    """Cierra las conexiones del pool al apagar la aplicación."""
    pool.close()
    logger.info("Pool de PostgreSQL cerrado")


@contextmanager
def conexion(conn: Connection | None = None) -> Iterator[Connection]:
    """Entrega una conexión y confirma la transacción al salir.

    Si se recibe una conexión ya abierta, se reutiliza para que varias operaciones
    (votar, denunciar, sumarse, marcar leídas) formen una sola transacción.
    """
    if conn is not None:
        yield conn
        return
    with pool.connection() as propia:
        yield propia
