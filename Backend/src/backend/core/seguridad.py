"""Hash y verificación de contraseñas.

Todo el hashing de la aplicación pasa por este módulo:

- Los hashes nuevos usan Argon2id con los parámetros por defecto de `argon2-cffi`.
- Los hashes heredados (SHA-256 hexadecimal de 64 caracteres) se aceptan una sola vez:
  al iniciar sesión con la clave correcta se reemplazan por Argon2id.
- Nunca se registran claves ni hashes en logs ni en mensajes de error.
"""

from __future__ import annotations

import hashlib
import hmac
import os
import re

from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError, VerifyMismatchError

PREFIJO_ARGON2 = "$argon2"
_SHA256_HEX = re.compile(r"^[0-9a-fA-F]{64}$")


def _crear_hasher() -> PasswordHasher:
    """Hasher de producción o uno reducido para el entorno de pruebas.

    Los tests activan `RADAR_ARGON2_RAPIDO=1` en `tests/conftest.py`; la aplicación
    normal siempre usa los parámetros por defecto (argon2id).
    """
    if os.getenv("RADAR_ARGON2_RAPIDO") == "1":
        return PasswordHasher(time_cost=1, memory_cost=8, parallelism=1, hash_len=16, salt_len=8)
    return PasswordHasher()


_hasher = _crear_hasher()


def hashear(clave: str) -> str:
    """Devuelve un hash Argon2id nuevo. Nunca se registra la clave."""
    return _hasher.hash(clave)


def verificar_clave(clave: str, clave_hash: str) -> tuple[bool, str | None]:
    """Verifica una clave y, si corresponde, devuelve el hash que debe guardarse.

    Retorna `(valida, hash_nuevo)`:

    - `(True, None)`: la clave es correcta y el hash actual sigue vigente.
    - `(True, "<hash argon2id>"): la clave es correcta y conviene migrar el hash`
      (SHA-256 heredado o Argon2 con parámetros desactualizados).
    - `(False, None)`: credenciales inválidas. No se expone el motivo.
    """
    if not clave_hash:
        return False, None

    if clave_hash.startswith(PREFIJO_ARGON2):
        try:
            _hasher.verify(clave_hash, clave)
        except (VerifyMismatchError, InvalidHashError, VerificationError):
            # Hash corrupto, truncado o de otro algoritmo: credenciales inválidas.
            return False, None
        if _hasher.check_needs_rehash(clave_hash):
            return True, _hasher.hash(clave)
        return True, None

    if _SHA256_HEX.fullmatch(clave_hash):
        calculado = hashlib.sha256(clave.encode()).hexdigest()
        if hmac.compare_digest(clave_hash.lower(), calculado):
            # Migración transparente: la próxima verificación ya usará Argon2id.
            return True, _hasher.hash(clave)

    return False, None
