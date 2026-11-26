"""Pruebas de hash Argon2id, migración transparente y cuentas de demostración."""

import hashlib
from datetime import UTC, datetime, timedelta
from unittest.mock import MagicMock

import pytest

from backend.core.seguridad import hashear, verificar_clave
from backend.schemas.barrios import Barrio
from backend.schemas.usuarios import Login, UsuarioDB
from backend.services import datos_iniciales
from backend.services.exceptions import NoAutenticadoError
from backend.services.usuarios import UsuarioService

SHA256_123456 = "8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92"


def _usuario(clave_hash: str, *, id_usuario: str = "v1") -> UsuarioDB:
    return UsuarioDB(
        id=id_usuario,
        nombre="Vecino Test",
        dni="40000001",
        correo="test@barrio.com",
        clave_hash=clave_hash,
        rol="vecino",
        id_barrio="b1",
        estado="Verificado",
        fecha_registro=datetime.now(UTC) - timedelta(days=10),
    )


def _servicio_login(clave_hash: str) -> tuple[UsuarioService, MagicMock, UsuarioDB]:
    repo = MagicMock()
    usuario = _usuario(clave_hash)
    repo.get_by_correo.return_value = usuario
    repo.actualizar_clave_hash = MagicMock()
    servicio = UsuarioService(repository=repo, barrios=MagicMock())
    return servicio, repo, usuario


# ---------------------------------------------------------------------------
# 1. Hash nuevo
# ---------------------------------------------------------------------------
def test_login_sigue_aceptando_la_clave_corta_de_las_cuentas_demo():
    """La validación de fortaleza solo aplica al registro, nunca al login."""
    assert Login(correo="vecino@barrio.com", clave="123456").clave == "123456"


def test_hash_nuevo_es_argon2id_y_verifica():
    hash_nuevo = hashear("clave-segura")

    assert hash_nuevo.startswith("$argon2id$")
    assert verificar_clave("clave-segura", hash_nuevo) == (True, None)
    assert verificar_clave("clave-incorrecta", hash_nuevo) == (False, None)


# ---------------------------------------------------------------------------
# 2. Hash heredado SHA-256: migración al iniciar sesión
# ---------------------------------------------------------------------------
def test_login_con_sha256_correcto_migra_a_argon2id():
    servicio, repo, _ = _servicio_login(SHA256_123456)

    autenticado = servicio.login(Login(correo="test@barrio.com", clave="123456"))

    assert autenticado.clave_hash.startswith("$argon2id$")
    repo.actualizar_clave_hash.assert_called_once()
    id_actualizado, hash_guardado = repo.actualizar_clave_hash.call_args[0]
    assert id_actualizado == "v1"
    assert hash_guardado.startswith("$argon2id$")
    assert verificar_clave("123456", hash_guardado)[0] is True


def test_login_con_sha256_incorrecto_no_migra():
    servicio, repo, _ = _servicio_login(SHA256_123456)

    with pytest.raises(NoAutenticadoError):
        servicio.login(Login(correo="test@barrio.com", clave="otra-clave"))

    repo.actualizar_clave_hash.assert_not_called()


def test_login_legacy_de_otra_clave_no_se_sobrescribe():
    otro_sha = hashlib.sha256(b"clave-propia").hexdigest()
    servicio, repo, _ = _servicio_login(otro_sha)

    with pytest.raises(NoAutenticadoError):
        servicio.login(Login(correo="test@barrio.com", clave="123456"))

    repo.actualizar_clave_hash.assert_not_called()


def test_login_argon2_correcto_no_se_rehashea_sin_necesidad():
    servicio, repo, _ = _servicio_login(hashear("123456"))

    autenticado = servicio.login(Login(correo="test@barrio.com", clave="123456"))

    assert autenticado.clave_hash.startswith("$argon2id$")
    repo.actualizar_clave_hash.assert_not_called()


def test_login_argon2_con_parametros_viejos_se_rehashea():
    from argon2 import PasswordHasher

    hasher_viejo = PasswordHasher(
        time_cost=2, memory_cost=1024, parallelism=1, hash_len=16, salt_len=8
    )
    servicio, repo, _ = _servicio_login(hasher_viejo.hash("123456"))

    autenticado = servicio.login(Login(correo="test@barrio.com", clave="123456"))

    assert autenticado.clave_hash.startswith("$argon2id$")
    repo.actualizar_clave_hash.assert_called_once()


# ---------------------------------------------------------------------------
# 3. Hashes corruptos o de otro tipo: credenciales inválidas, sin excepción 500
# ---------------------------------------------------------------------------
@pytest.mark.parametrize(
    "hash_invalido",
    [
        "",
        "no-es-un-hash",
        "z" * 64,  # 64 caracteres pero no hexadecimal
        "$2b$12$abcdefghijklmnopqrstuv",  # bcrypt
        "$argon2id$corrupto",
        "$argon2id$v=19$m=65536,t=3,p=4$abc$def",
    ],
)
def test_hash_corrupto_o_de_otro_tipo_no_rompe_el_servidor(hash_invalido):
    servicio, repo, _ = _servicio_login(hash_invalido)

    with pytest.raises(NoAutenticadoError):
        servicio.login(Login(correo="test@barrio.com", clave="123456"))

    repo.actualizar_clave_hash.assert_not_called()


# ---------------------------------------------------------------------------
# 4. Cuentas de demostración: un solo hash Argon2id reutilizado
# ---------------------------------------------------------------------------
def test_cuentas_de_demostracion_usan_un_unico_hash_argon2id():
    barrios = [
        Barrio(
            id=f"b{i}",
            nombre=f"Barrio {i}",
            poligono=[(-12.10, -75.25), (-12.00, -75.25), (-12.00, -75.15), (-12.10, -75.15)],
        )
        for i in range(1, 10)
    ]
    conn = MagicMock()

    datos_iniciales._cargar_usuarios(conn, datetime.now(UTC), barrios)

    cursor = conn.cursor.return_value.__enter__.return_value
    filas = cursor.executemany.call_args[0][1]
    hashes = {fila[4] for fila in filas}

    assert len(filas) == 41  # 36 vecinos + 4 pendientes + m1
    assert len(hashes) == 1  # el hash se calcula una sola vez
    unico_hash = hashes.pop()
    assert unico_hash.startswith("$argon2id$")
    assert verificar_clave("123456", unico_hash) == (True, None)

    # Las cuentas de la demo entran con la clave 123456.
    for fila in filas:
        id_usuario, nombre, dni, correo, clave_hash, rol, id_barrio, estado, fecha = fila[:9]
        usuario = UsuarioDB(
            id=id_usuario,
            nombre=nombre,
            dni=dni,
            correo=correo,
            clave_hash=clave_hash,
            rol=rol,
            id_barrio=id_barrio,
            estado=estado,
            fecha_registro=fecha,
        )
        repo = MagicMock()
        repo.get_by_correo.return_value = usuario
        servicio = UsuarioService(repository=repo, barrios=MagicMock())
        assert servicio.login(Login(correo=correo, clave="123456")).id == id_usuario
