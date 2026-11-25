"""Pruebas de IDs con secuencias usando repositorios simulados (sin base real)."""

import re
from contextlib import contextmanager
from datetime import UTC, date, datetime, timedelta
from unittest.mock import MagicMock

from backend.repositories.secuencias import siguiente_id
from backend.repositories.usuarios import UsuarioRepository
from backend.schemas.acciones import AccionCreate
from backend.schemas.barrios import Barrio
from backend.schemas.iniciativas import IniciativaCreate
from backend.schemas.reportes import ReporteCreate
from backend.schemas.usuarios import UsuarioDB, UsuarioRegistro
from backend.services.acciones import AccionService
from backend.services.alertas import AlertaService
from backend.services.iniciativas import IniciativaService
from backend.services.reportes import ReporteService
from backend.services.usuarios import UsuarioService


class SecuenciaFalsa:
    """Simula `nextval` de PostgreSQL: <prefijo>1, <prefijo>2, ..."""

    def __init__(self, prefijo: str) -> None:
        self.prefijo = prefijo
        self.contador = 0

    def __call__(self, *args, **kwargs) -> str:
        self.contador += 1
        return f"{self.prefijo}{self.contador}"


def _usuario(id_usuario: str = "v1", rol: str = "vecino", id_barrio: str | None = "b1") -> UsuarioDB:
    return UsuarioDB(
        id=id_usuario,
        nombre="Vecino Test",
        dni="40000001",
        correo=f"{id_usuario}@barrio.com",
        clave_hash="hash-no-usado-en-estas-pruebas",
        rol=rol,
        id_barrio=id_barrio,
        estado="Verificado",
        fecha_registro=datetime.now(UTC) - timedelta(days=10),
        institucion="Municipalidad" if rol == "municipalidad" else None,
    )


def _barrio() -> Barrio:
    return Barrio(
        id="b1",
        nombre="Torre Torre",
        poligono=[(-12.06, -75.20), (-12.04, -75.20), (-12.04, -75.18), (-12.06, -75.18)],
    )


def _assert_formato(ids: list[str], prefijo: str) -> None:
    patron = re.compile(rf"^{prefijo}[0-9]+$")
    assert all(patron.fullmatch(id_) for id_ in ids), ids
    assert len(set(ids)) == len(ids)  # dos IDs consecutivos nunca coinciden


def test_siguiente_id_usa_nextval_con_parametros(monkeypatch):
    conn = MagicMock()
    conn.execute.return_value.fetchone.return_value = {"id": "v41"}

    @contextmanager
    def conexion_simulada(_=None):
        yield conn

    monkeypatch.setattr("backend.repositories.secuencias.conexion", conexion_simulada)

    assert siguiente_id("v", "seq_usuarios_vecinos") == "v41"

    sentencia, parametros = conn.execute.call_args[0]
    assert "nextval" in sentencia
    assert parametros == ("v", "seq_usuarios_vecinos")


def test_repositorio_usuarios_mapea_rol_a_prefijo_y_secuencia(monkeypatch):
    llamadas = []

    def siguiente_id_simulado(prefijo, secuencia, conn=None):
        llamadas.append((prefijo, secuencia))
        return f"{prefijo}1"

    monkeypatch.setattr("backend.repositories.usuarios.siguiente_id", siguiente_id_simulado)
    repo = UsuarioRepository()

    assert repo.siguiente_id("vecino") == "v1"
    assert repo.siguiente_id("municipalidad") == "m1"
    assert llamadas == [
        ("v", "seq_usuarios_vecinos"),
        ("m", "seq_usuarios_municipalidad"),
    ]


def test_registro_genera_ids_v_consecutivos_distintos():
    repo = MagicMock()
    repo.get_by_dni.return_value = None
    repo.get_by_correo.return_value = None
    repo.siguiente_id = SecuenciaFalsa("v")
    repo.add.side_effect = lambda u: u

    barrios = MagicMock()
    barrios.get.return_value = _barrio()
    barrios.validar_codigo.return_value = True
    servicio = UsuarioService(repository=repo, barrios=barrios)

    ids = []
    for i in range(2):
        creado = servicio.registrar(
            UsuarioRegistro(
                nombre=f"Vecino {i}",
                dni=f"4567890{i}",
                correo=f"vecino{i}@correo.com",
                clave="123456",
                id_barrio="b1",
                codigo_barrio="TORRE-2026",
            )
        )
        ids.append(creado.id)

    _assert_formato(ids, "v")


def test_reportes_generan_ids_r_consecutivos_distintos():
    repo = MagicMock()
    repo.list.return_value = []
    repo.siguiente_id = SecuenciaFalsa("r")
    repo.add.side_effect = lambda r: r

    barrios = MagicMock()
    barrios.list.return_value = [_barrio()]
    servicio = ReporteService(repository=repo, barrios=barrios)

    ids = []
    for i in range(2):
        creado = servicio.crear(
            ReporteCreate(
                lat=-12.05,
                lng=-75.19,
                tipo="otro",
                descripcion=f"Incidente distinto {i}",
            ),
            _usuario(),
        )
        ids.append(creado.id)

    _assert_formato(ids, "r")


def test_acciones_generan_ids_a_consecutivos_distintos():
    repo = MagicMock()
    repo.list.return_value = []
    repo.siguiente_id = SecuenciaFalsa("a")
    repo.add.side_effect = lambda a: a

    barrios = MagicMock()
    barrios.get.return_value = _barrio()
    servicio = AccionService(
        repository=repo,
        barrios=barrios,
        zonas=MagicMock(),
        reportes=MagicMock(),
    )

    ids = []
    for i in range(2):
        creada = servicio.crear(
            AccionCreate(
                id_barrio="b1",
                tipo="Otro",
                titulo=f"Acción {i}",
                descripcion=f"Descripción {i}",
                fecha=date(2026, 1, 1),
                estado="Planificada",
            ),
            _usuario("m1", "municipalidad", None),
        )
        ids.append(creada.id)

    _assert_formato(ids, "a")


def test_iniciativas_generan_ids_i_consecutivos_distintos():
    repo = MagicMock()
    repo.siguiente_id = SecuenciaFalsa("i")
    repo.add.side_effect = lambda i: i

    servicio = IniciativaService(repository=repo, zonas=MagicMock())

    ids = []
    for i in range(2):
        creada = servicio.crear(
            IniciativaCreate(
                titulo=f"Iniciativa {i}",
                descripcion=f"Descripción {i}",
                meta="10 vecinos",
                estado="Propuesta",
            ),
            _usuario(),
        )
        ids.append(creada.id)

    _assert_formato(ids, "i")


def test_alertas_generan_ids_al_consecutivos_distintos():
    repo = MagicMock()
    repo.get.return_value = None
    repo.siguiente_id = SecuenciaFalsa("al")
    repo.set.side_effect = lambda a: a

    servicio = AlertaService(repository=repo)

    ids = [servicio.activar(_usuario()).id for _ in range(2)]

    _assert_formato(ids, "al")
