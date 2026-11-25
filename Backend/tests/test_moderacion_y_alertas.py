"""Pruebas unitarias de moderación, control de alertas y anti-spam."""

from datetime import UTC, datetime, timedelta
from unittest.mock import MagicMock
import pytest

from backend.core.seguridad import hashear
from backend.schemas.barrios import Barrio
from backend.schemas.paneles import Alerta
from backend.schemas.reportes import Reporte, ReporteCreate
from backend.schemas.usuarios import Login, ModerarUsuarioRequest, UsuarioDB
from backend.services.alertas import AlertaService
from backend.services.exceptions import AccesoDenegadoError, LimiteExcedidoError
from backend.services.reportes import ReporteService
from backend.services.usuarios import UsuarioService


def _crear_usuario(
    id_usuario="v1",
    nombre="Vecino Test",
    estado="Verificado",
    strikes=0,
    suspendido_hasta=None,
    motivo_sancion=None,
    rol="vecino",
    id_barrio="b1",
):
    return UsuarioDB(
        id=id_usuario,
        nombre=nombre,
        dni="40000001",
        correo="test@barrio.com",
        clave_hash=hashear("123456"),
        rol=rol,
        id_barrio=id_barrio,
        estado=estado,
        fecha_registro=datetime.now(UTC) - timedelta(days=10),
        strikes=strikes,
        suspendido_hasta=suspendido_hasta,
        motivo_sancion=motivo_sancion,
    )


# =========================================================================
# 1. BLOQUEO DE USUARIOS BANEADOS Y SUSPENDIDOS / AUTO-REACTIVACIÓN
# =========================================================================
def test_usuario_baneado_bloquea_login_y_sesion():
    repo_usuarios = MagicMock()
    repo_barrios = MagicMock()
    usuario_baneado = _crear_usuario(estado="Baneado", motivo_sancion="3 strikes acumulados")
    repo_usuarios.get_by_correo.return_value = usuario_baneado
    repo_usuarios.get.return_value = usuario_baneado

    servicio = UsuarioService(repository=repo_usuarios, barrios=repo_barrios)

    # Intento de login
    with pytest.raises(AccesoDenegadoError) as exc_login:
        servicio.login(Login(correo="test@barrio.com", clave="123456"))
    assert "bloqueada permanentemente" in str(exc_login.value)

    # Intento de sesión con encabezado X-Usuario-Id
    with pytest.raises(AccesoDenegadoError) as exc_sesion:
        servicio.usuario_actual("v1")
    assert "bloqueada permanentemente" in str(exc_sesion.value)


def test_usuario_suspendido_activo_bloquea_acceso():
    repo_usuarios = MagicMock()
    repo_barrios = MagicMock()
    manana = datetime.now(UTC) + timedelta(days=1)
    usuario_suspendido = _crear_usuario(estado="Suspendido", suspendido_hasta=manana)
    repo_usuarios.get_by_correo.return_value = usuario_suspendido
    repo_usuarios.get.return_value = usuario_suspendido

    servicio = UsuarioService(repository=repo_usuarios, barrios=repo_barrios)

    with pytest.raises(AccesoDenegadoError) as exc:
        servicio.usuario_actual("v1")
    assert "suspendida temporalmente hasta" in str(exc.value)


def test_usuario_suspendido_expirado_se_reactiva_automaticamente():
    repo_usuarios = MagicMock()
    repo_barrios = MagicMock()
    ayer = datetime.now(UTC) - timedelta(days=1)
    usuario_expirado = _crear_usuario(estado="Suspendido", suspendido_hasta=ayer)
    repo_usuarios.get.return_value = usuario_expirado
    repo_usuarios.update.side_effect = lambda u: u

    servicio = UsuarioService(repository=repo_usuarios, barrios=repo_barrios)

    reactivado = servicio.usuario_actual("v1")
    assert reactivado.estado == "Verificado"
    assert reactivado.suspendido_hasta is None
    assert reactivado.motivo_sancion is None
    repo_usuarios.update.assert_called_once()


# =========================================================================
# 2. REGLA DE 3 STRIKES Y BAN AUTOMÁTICO
# =========================================================================
def test_strike_suma_infraccion_y_al_tercero_aplica_ban():
    repo_usuarios = MagicMock()
    usuario = _crear_usuario(strikes=0)
    repo_usuarios.get.return_value = usuario
    repo_usuarios.update.side_effect = lambda u: u

    servicio = UsuarioService(repository=repo_usuarios)

    # Strike 1
    u1 = servicio.registrar_strike("v1", "Reporte falso #r1")
    assert u1.strikes == 1
    assert u1.estado == "Verificado"

    # Strike 2
    repo_usuarios.get.return_value = u1
    u2 = servicio.registrar_strike("v1", "Falsa alarma #a1")
    assert u2.strikes == 2
    assert u2.estado == "Verificado"

    # Strike 3 -> Ban automático
    repo_usuarios.get.return_value = u2
    u3 = servicio.registrar_strike("v1", "Reporte falso #r2")
    assert u3.strikes == 3
    assert u3.estado == "Baneado"
    assert "Ban automático por acumular 3 infracciones" in u3.motivo_sancion


# =========================================================================
# 3. ANTI-SPAM EN CREACIÓN DE REPORTES
# =========================================================================
def _servicio_reportes(reportes_existentes=None):
    repo_reportes = MagicMock()
    repo_barrios = MagicMock()
    barrio = Barrio(
        id="b1",
        nombre="Torre Torre",
        poligono=[(-12.06, -75.20), (-12.04, -75.20), (-12.04, -75.18), (-12.06, -75.18)],
    )
    repo_barrios.list.return_value = [barrio]
    repo_barrios.get.return_value = barrio

    repo_reportes.list.return_value = list(reportes_existentes or [])
    repo_reportes.siguiente_id.return_value = "r999"
    repo_reportes.add.side_effect = lambda r: r

    servicio = ReporteService(repository=repo_reportes, barrios=repo_barrios)
    return servicio, repo_reportes


def test_antispam_maximo_tres_reportes_en_60_minutos():
    ahora = datetime.now(UTC)
    reportes_previos = [
        Reporte(
            id=f"r_{i}",
            lat=-12.05,
            lng=-75.19,
            id_barrio="b1",
            tipo="asalto_robo",
            gravedad=5,
            descripcion=f"Incidente distinto {i}",
            fecha=ahora - timedelta(minutes=10 * (i + 1)),
            estado="activo",
            confirmaciones=0,
            id_usuario="v1",
        )
        for i in range(3)
    ]

    servicio, _ = _servicio_reportes(reportes_previos)
    usuario = _crear_usuario()

    datos = ReporteCreate(
        lat=-12.05,
        lng=-75.19,
        tipo="falta_alumbrado",
        descripcion="Cuarto reporte que debe ser bloqueado",
    )

    with pytest.raises(LimiteExcedidoError) as exc:
        servicio.crear(datos, usuario)
    assert "Has alcanzado el límite temporal de reportes" in str(exc.value)


def test_antispam_minimo_tres_minutos_entre_reportes():
    ahora = datetime.now(UTC)
    reportes_previos = [
        Reporte(
            id="r_reciente",
            lat=-12.05,
            lng=-75.19,
            id_barrio="b1",
            tipo="asalto_robo",
            gravedad=5,
            descripcion="Incidente hace 1 minuto",
            fecha=ahora - timedelta(minutes=1),
            estado="activo",
            confirmaciones=0,
            id_usuario="v1",
        )
    ]

    servicio, _ = _servicio_reportes(reportes_previos)
    usuario = _crear_usuario()

    datos = ReporteCreate(
        lat=-12.05,
        lng=-75.19,
        tipo="falta_alumbrado",
        descripcion="Nuevo reporte pero muy rápido",
    )

    with pytest.raises(LimiteExcedidoError) as exc:
        servicio.crear(datos, usuario)
    assert "Has alcanzado el límite temporal de reportes" in str(exc.value)


def test_antispam_descripcion_duplicada():
    ahora = datetime.now(UTC)
    reportes_previos = [
        Reporte(
            id="r_existente",
            lat=-12.05,
            lng=-75.19,
            id_barrio="b1",
            tipo="asalto_robo",
            gravedad=5,
            descripcion="Robo a mano armada en la esquina",
            fecha=ahora - timedelta(minutes=15),
            estado="activo",
            confirmaciones=0,
            id_usuario="v1",
        )
    ]

    servicio, _ = _servicio_reportes(reportes_previos)
    usuario = _crear_usuario()

    datos = ReporteCreate(
        lat=-12.05,
        lng=-75.19,
        tipo="asalto_robo",
        descripcion="  robo a mano   armada en la ESQUINA  ",  # misma descripción normalizada
    )

    with pytest.raises(LimiteExcedidoError) as exc:
        servicio.crear(datos, usuario)
    assert "Has alcanzado el límite temporal de reportes" in str(exc.value)


# =========================================================================
# 4. MODERACIÓN DE REPORTES FALSOS Y PURGA DE SPAM
# =========================================================================
def test_moderar_marcar_falso_aplica_un_strike_al_autor(monkeypatch):
    mock_registrar_strike = MagicMock()
    monkeypatch.setattr("backend.services.reportes.usuario_service.registrar_strike", mock_registrar_strike)

    ahora = datetime.now(UTC)
    reporte = Reporte(
        id="r100",
        lat=-12.05,
        lng=-75.19,
        id_barrio="b1",
        tipo="asalto_robo",
        gravedad=5,
        descripcion="Reporte inventado",
        fecha=ahora,
        estado="activo",
        confirmaciones=0,
        id_usuario="v_infractor",
    )

    repo_reportes = MagicMock()
    repo_reportes.get.return_value = reporte
    repo_reportes.update.side_effect = lambda r: r

    servicio = ReporteService(repository=repo_reportes)

    res = servicio.moderar_reporte("r100", "marcar_falso")
    assert "marcado como falso" in res["detail"]
    repo_reportes.update.assert_called_once()
    actualizado = repo_reportes.update.call_args[0][0]
    assert actualizado.estado == "falso"

    # Verificamos que se llamó a registrar_strike para el autor
    mock_registrar_strike.assert_called_once()
    assert mock_registrar_strike.call_args[0][0] == "v_infractor"


def test_moderar_purgar_spam_purga_reportes_y_aplica_ban(monkeypatch):
    mock_moderar_usuario = MagicMock()
    monkeypatch.setattr("backend.services.reportes.usuario_service.moderar", mock_moderar_usuario)

    ahora = datetime.now(UTC)
    reporte = Reporte(
        id="r200",
        lat=-12.05,
        lng=-75.19,
        id_barrio="b1",
        tipo="asalto_robo",
        gravedad=5,
        descripcion="Spam 1",
        fecha=ahora,
        estado="activo",
        confirmaciones=0,
        id_usuario="v_spammer",
    )

    repo_reportes = MagicMock()
    repo_reportes.get.return_value = reporte
    repo_reportes.purgar_por_usuario.return_value = 5

    servicio = ReporteService(repository=repo_reportes)

    res = servicio.moderar_reporte("r200", "purgar_spam")
    assert "purgados y usuario baneado" in res["detail"]
    repo_reportes.purgar_por_usuario.assert_called_once_with("v_spammer")
    mock_moderar_usuario.assert_called_once()
    assert mock_moderar_usuario.call_args[0][0] == "v_spammer"
    assert mock_moderar_usuario.call_args[0][1].accion == "banear"


# =========================================================================
# 5. CANCELACIÓN DE ALERTA POR FALSA ALARMA
# =========================================================================
def test_cancelar_alerta_falsa_alarma_aplica_strike(monkeypatch):
    mock_registrar_strike = MagicMock()
    monkeypatch.setattr("backend.services.alertas.usuario_service.registrar_strike", mock_registrar_strike)

    ahora = datetime.now(UTC)
    alerta = Alerta(
        id="alerta_1",
        id_barrio="b1",
        inicio=ahora,
        expira=ahora + timedelta(minutes=30),
        id_usuario="v_bromista",
        nombre_barrio="Torre Torre",
    )

    repo_alertas = MagicMock()
    repo_alertas.get_por_id.return_value = alerta
    repo_alertas.delete.return_value = True

    servicio = AlertaService(repository=repo_alertas)

    res = servicio.cancelar("alerta_1", "falsa_alarma")
    assert "falsa alarma (+1 strike aplicado" in res["detail"]
    mock_registrar_strike.assert_called_once()
    assert mock_registrar_strike.call_args[0][0] == "v_bromista"
    repo_alertas.delete.assert_called_once_with("alerta_1")


def test_cancelar_alerta_atendida_no_sanciona(monkeypatch):
    mock_registrar_strike = MagicMock()
    monkeypatch.setattr("backend.services.alertas.usuario_service.registrar_strike", mock_registrar_strike)

    ahora = datetime.now(UTC)
    alerta = Alerta(
        id="alerta_2",
        id_barrio="b1",
        inicio=ahora,
        expira=ahora + timedelta(minutes=30),
        id_usuario="v_vecino_real",
        nombre_barrio="Torre Torre",
    )

    repo_alertas = MagicMock()
    repo_alertas.get_por_id.return_value = alerta
    repo_alertas.delete.return_value = True

    servicio = AlertaService(repository=repo_alertas)

    res = servicio.cancelar("alerta_2", "atendida")
    assert "Alerta atendida con éxito" in res["detail"]
    mock_registrar_strike.assert_not_called()
    repo_alertas.delete.assert_called_once_with("alerta_2")


# =========================================================================
# 6. MODERACIÓN MANUAL DE VECINOS (SUSPENDER, BANEAR, REACTIVAR)
# =========================================================================
def test_moderacion_manual_suspender_banear_reactivar():
    repo_usuarios = MagicMock()
    usuario = _crear_usuario(strikes=2)
    repo_usuarios.get.return_value = usuario
    repo_usuarios.update.side_effect = lambda u: u

    servicio = UsuarioService(repository=repo_usuarios)

    # Suspender 7 días
    s1 = servicio.moderar(
        "v1", ModerarUsuarioRequest(accion="suspender", dias=7, motivo="Conducta reiterada")
    )
    assert s1.estado == "Suspendido"
    assert s1.suspendido_hasta is not None
    assert "Conducta reiterada" in s1.motivo_sancion

    # Banear
    s2 = servicio.moderar(
        "v1", ModerarUsuarioRequest(accion="banear", motivo="Infracción grave")
    )
    assert s2.estado == "Baneado"
    assert "Infracción grave" in s2.motivo_sancion

    # Reactivar cuenta (limpia strikes, fechas y estado)
    s3 = servicio.moderar(
        "v1", ModerarUsuarioRequest(accion="reactivar")
    )
    assert s3.estado == "Verificado"
    assert s3.strikes == 0
    assert s3.suspendido_hasta is None
    assert s3.motivo_sancion is None
