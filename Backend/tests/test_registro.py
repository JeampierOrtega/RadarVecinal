"""Pruebas unitarias del registro de vecinos con DNI y código de barrio."""

from unittest.mock import MagicMock
import pytest
from pydantic import ValidationError

from backend.schemas.barrios import Barrio
from backend.schemas.usuarios import UsuarioDB, UsuarioRegistro
from backend.services.exceptions import ConflictoError, SolicitudIncorrectaError
from backend.services.usuarios import UsuarioService


def _servicio_con_mocks():
    repo_usuarios = MagicMock()
    repo_barrios = MagicMock()

    # Por defecto, el barrio b1 existe
    repo_barrios.get.side_effect = lambda id_b: (
        Barrio(id="b1", nombre="Torre Torre", poligono=[(0.0, 0.0), (1.0, 1.0)])
        if id_b == "b1"
        else None
    )
    # Por defecto, el código es válido para b1
    repo_barrios.validar_codigo.side_effect = (
        lambda id_b, cod: id_b == "b1" and cod.strip().upper() == "TORRE-2026"
    )
    # Por defecto, no existen duplicados y el ID sale de la secuencia simulada
    repo_usuarios.get_by_dni.return_value = None
    repo_usuarios.get_by_correo.return_value = None
    repo_usuarios.siguiente_id.return_value = "v41"
    repo_usuarios.add.side_effect = lambda u: u

    servicio = UsuarioService(repository=repo_usuarios, barrios=repo_barrios)
    return servicio, repo_usuarios, repo_barrios


def test_registro_exitoso_queda_verificado():
    servicio, repo_usuarios, _ = _servicio_con_mocks()
    datos = UsuarioRegistro(
        nombre="Juan Pérez",
        dni="45678901",
        correo="juan@correo.com",
        clave="Radar2026!",
        id_barrio="b1",
        codigo_barrio="TORRE-2026",
    )

    creado = servicio.registrar(datos)

    assert creado.dni == "45678901"
    assert creado.estado == "Verificado"
    assert creado.rol == "vecino"
    assert creado.id_barrio == "b1"
    assert creado.correo == "juan@correo.com"
    repo_usuarios.add.assert_called_once()


def test_registro_rechaza_codigo_invalido():
    servicio, _, _ = _servicio_con_mocks()
    datos = UsuarioRegistro(
        nombre="Juan Pérez",
        dni="45678901",
        correo="juan@correo.com",
        clave="Radar2026!",
        id_barrio="b1",
        codigo_barrio="CODIGO-ERRONEO",
    )

    with pytest.raises(SolicitudIncorrectaError) as exc_info:
        servicio.registrar(datos)

    assert "El código de acceso no corresponde al barrio seleccionado o ha expirado" in str(
        exc_info.value
    )


def test_registro_rechaza_dni_duplicado():
    servicio, repo_usuarios, _ = _servicio_con_mocks()
    repo_usuarios.get_by_dni.return_value = MagicMock(spec=UsuarioDB)

    datos = UsuarioRegistro(
        nombre="Juan Pérez",
        dni="45678901",
        correo="juan@correo.com",
        clave="Radar2026!",
        id_barrio="b1",
        codigo_barrio="TORRE-2026",
    )

    with pytest.raises(ConflictoError) as exc_info:
        servicio.registrar(datos)

    assert "Este DNI ya se encuentra registrado" in str(exc_info.value)


def test_registro_rechaza_correo_duplicado():
    servicio, repo_usuarios, _ = _servicio_con_mocks()
    repo_usuarios.get_by_correo.return_value = MagicMock(spec=UsuarioDB)

    datos = UsuarioRegistro(
        nombre="Juan Pérez",
        dni="45678901",
        correo="juan@correo.com",
        clave="Radar2026!",
        id_barrio="b1",
        codigo_barrio="TORRE-2026",
    )

    with pytest.raises(ConflictoError) as exc_info:
        servicio.registrar(datos)

    assert "Ya existe una cuenta con el correo" in str(exc_info.value)


def test_registro_rechaza_barrio_inexistente():
    servicio, _, _ = _servicio_con_mocks()
    datos = UsuarioRegistro(
        nombre="Juan Pérez",
        dni="45678901",
        correo="juan@correo.com",
        clave="Radar2026!",
        id_barrio="b999",
        codigo_barrio="TORRE-2026",
    )

    with pytest.raises(SolicitudIncorrectaError) as exc_info:
        servicio.registrar(datos)

    assert "El barrio seleccionado no existe" in str(exc_info.value)


@pytest.mark.parametrize(
    "clave",
    [
        "Corta1!",  # menos de 8 caracteres
        "radar2026!",  # sin mayúscula
        "RadarSegura!",  # sin número
        "Radar2026",  # sin símbolo
    ],
)
def test_esquema_rechaza_claves_debiles(clave):
    with pytest.raises(ValidationError) as exc_info:
        UsuarioRegistro(
            nombre="Juan Pérez",
            dni="45678901",
            correo="juan@correo.com",
            clave=clave,
            id_barrio="b1",
            codigo_barrio="TORRE-2026",
        )

    assert "contraseña" in str(exc_info.value).lower()


def test_esquema_rechaza_dni_formato_invalido():
    with pytest.raises(ValidationError):
        UsuarioRegistro(
            nombre="Juan Pérez",
            dni="12345",  # menos de 8 dígitos
            correo="juan@correo.com",
            clave="Radar2026!",
            id_barrio="b1",
            codigo_barrio="TORRE-2026",
        )

    with pytest.raises(ValidationError):
        UsuarioRegistro(
            nombre="Juan Pérez",
            dni="1234567A",  # contiene letras
            correo="juan@correo.com",
            clave="Radar2026!",
            id_barrio="b1",
            codigo_barrio="TORRE-2026",
        )
