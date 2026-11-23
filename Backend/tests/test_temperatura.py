"""Tests de la temperatura de los barrios (funciones puras, sin base de datos).

Todo se construye a mano con una fecha "ahora" fija: el resultado no depende del
estado de PostgreSQL ni de los reportes que existan en ese momento.
"""

import math
from datetime import UTC, datetime, timedelta

import pytest

from backend.schemas.reportes import Reporte, TipoIncidente
from backend.services.temperatura import (
    BONO_NOVEDAD_TOPE,
    GRAVEDAD,
    VIDA_MEDIA_DIAS,
    bono_novedad,
    bono_novedad_zona,
    nivel_temperatura,
    peso_reporte,
    temperatura_zona,
)

AHORA = datetime(2026, 11, 22, 12, 0, tzinfo=UTC)


def _reporte(
    tipo: TipoIncidente,
    *,
    dias: float = 0.0,
    confirmaciones: int = 0,
    estado: str = "activo",
    id_reporte: str = "r_test",
) -> Reporte:
    """Reporte construido a mano, con la antigüedad que se le pida."""
    return Reporte(
        id=id_reporte,
        lat=-12.06,
        lng=-75.20,
        id_barrio="b1",
        tipo=tipo,
        gravedad=GRAVEDAD[tipo],
        descripcion="Reporte de prueba",
        fecha=AHORA - timedelta(days=dias),
        estado=estado,
        confirmaciones=confirmaciones,
        denuncias=0,
        id_usuario="v1",
    )


def _reporte_con_peso(objetivo: float) -> Reporte:
    """Reporte con la antigüedad justa para pesar exactamente `objetivo`.

    Lleva 3 confirmaciones (factor 1.5), así que un peso de 3.7 lo deja con más de
    15 días: sigue pesando 3.7 pero ya no tiene bono de novedad.
    """
    return _reporte(
        "asalto_robo",
        dias=VIDA_MEDIA_DIAS * math.log2(7.5 / objetivo),
        confirmaciones=3,
    )


# --- Un asalto nuevo ---


def test_un_asalto_en_un_barrio_sin_actividad_queda_en_verde():
    """5 (peso base) + 2 (bono) = 7.0, todavía por debajo del umbral 8."""
    asalto = _reporte("asalto_robo")

    total = temperatura_zona([asalto], AHORA)

    assert total == pytest.approx(7.0)
    assert nivel_temperatura(total) == "verde"


def test_un_asalto_en_un_barrio_con_3_7_previos_lo_pasa_a_amarillo():
    """El barrio más frío de la demo ronda 3.7: 3.7 + 7.0 = 10.7."""
    previo = _reporte_con_peso(3.7)
    asalto = _reporte("asalto_robo")

    assert peso_reporte(previo, AHORA) == pytest.approx(3.7)
    assert bono_novedad(previo, AHORA) == pytest.approx(0.0)  # ya tiene más de 7 días
    total = temperatura_zona([previo, asalto], AHORA)

    assert total == pytest.approx(10.7)
    assert nivel_temperatura(total) == "amarillo"


def test_el_peso_base_del_asalto_no_cambia():
    """El bono es un añadido: la escala base (gravedad × …) sigue igual."""
    assert peso_reporte(_reporte("asalto_robo"), AHORA) == pytest.approx(5.0)


# --- Dos y tres asaltos nuevos ---


def test_dos_asaltos_en_un_barrio_sin_actividad_dan_amarillo():
    """2 × 5 + 2 × 2 = 14.0 (ya cruza el umbral 8)."""
    asaltos = [
        _reporte("asalto_robo", id_reporte="r_1"),
        _reporte("asalto_robo", id_reporte="r_2"),
    ]

    total = temperatura_zona(asaltos, AHORA)

    assert total == pytest.approx(14.0)
    assert nivel_temperatura(total) == "amarillo"


def test_tres_asaltos_nuevos_dan_naranja():
    """3 × 5 + min(6, 3 × 2) = 15 + 6 = 21.0."""
    asaltos = [
        _reporte("asalto_robo", id_reporte="r_1"),
        _reporte("asalto_robo", id_reporte="r_2"),
        _reporte("asalto_robo", id_reporte="r_3"),
    ]

    total = temperatura_zona(asaltos, AHORA)

    assert total == pytest.approx(21.0)
    assert nivel_temperatura(total) == "naranja"


# --- Bono de novedad ---


def test_el_bono_baja_en_linea_recta_hasta_desaparecer():
    """+2 recién creado, +1 a los 3.5 días y 0 a los 7 días (sin cortes)."""
    assert bono_novedad(_reporte("asalto_robo", dias=0), AHORA) == pytest.approx(2.0)
    assert bono_novedad(_reporte("asalto_robo", dias=1.75), AHORA) == pytest.approx(1.5)
    assert bono_novedad(_reporte("asalto_robo", dias=3.5), AHORA) == pytest.approx(1.0)
    assert bono_novedad(_reporte("asalto_robo", dias=7), AHORA) == pytest.approx(0.0)
    assert bono_novedad(_reporte("asalto_robo", dias=8), AHORA) == pytest.approx(0.0)


def test_el_bono_por_barrio_no_pasa_de_mas_seis():
    """5 asaltos nuevos sumarían +10 de bono, pero el tope lo deja en +6."""
    asaltos = [
        _reporte("asalto_robo", id_reporte=f"r_{i}") for i in range(1, 6)
    ]

    assert bono_novedad_zona(asaltos, AHORA) == pytest.approx(BONO_NOVEDAD_TOPE)
    # 5 × 5 + 6 = 31.0 (por encima de 30, ya es rojo)
    assert temperatura_zona(asaltos, AHORA) == pytest.approx(31.0)
    assert nivel_temperatura(temperatura_zona(asaltos, AHORA)) == "rojo"


def test_un_reporte_falso_o_archivado_no_suma_bono():
    """Los descartados por la Municipalidad no calientan el barrio de ninguna forma."""
    falso = _reporte("asalto_robo", estado="falso", id_reporte="r_falso")
    archivado = _reporte("asalto_robo", estado="archivado", id_reporte="r_archivado")

    assert bono_novedad(falso, AHORA) == 0.0
    assert bono_novedad(archivado, AHORA) == 0.0
    assert bono_novedad_zona([falso, archivado], AHORA) == 0.0
    assert temperatura_zona([falso, archivado], AHORA) == 0.0
