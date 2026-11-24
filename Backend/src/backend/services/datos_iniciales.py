"""Datos de demostración para PostgreSQL (adaptados al prototipo de Lovable).

La carga es idempotente: cada grupo (usuarios, reportes, iniciativas, acciones) se
inserta solo si su tabla está vacía y todas las sentencias usan
`INSERT ... ON CONFLICT DO NOTHING`. Los barrios ya vienen cargados con el esquema.
Todas las cuentas de prueba usan la contraseña 123456.
"""

import logging
from datetime import UTC, datetime, timedelta

from psycopg import Connection

from backend.db import pool
from backend.repositories.barrios import barrio_repository
from backend.schemas.barrios import Barrio
from backend.services.temperatura import GRAVEDAD, barrio_del_punto, punto_en_poligono
from backend.services.usuarios import hashear

logger = logging.getLogger("radar_vecinal")

NOMBRES = [
    "Rosa Quispe",
    "Juan Huamán",
    "María Rojas",
    "Carlos Poma",
    "Lucía Ccanto",
    "Pedro Mendoza",
    "Ana Taipe",
    "Luis Cárdenas",
    "Elena Soto",
    "Jorge Inga",
    "Carmen Ríos",
    "Raúl Chávez",
    "Sofía Yupanqui",
    "Diego Ramos",
    "Patricia Vila",
    "Julio Ccahuana",
    "Marisol Laura",
    "Percy Quispe",
    "Yolanda Canchanya",
    "Fredy Baldeón",
    "Norma Pariona",
    "Alfredo Yupanqui",
    "Karina Camarena",
    "Rubén Sulca",
    "Betty Paucar",
    "Héctor Contreras",
    "Milagros Rojas",
    "Óscar Espinoza",
    "Diana Aylas",
    "Wilmer Torres",
    "Gladys Chuquillanqui",
    "César Santos",
    "Verónica Landa",
    "Abelardo Ñahui",
    "Roxana Cisneros",
    "Teodoro Mucha",
]  # fmt: skip

PLANTILLAS_POR_TIPO = {
    "asalto_robo": [
        "Robo al paso a mano armada a transeúnte en {calle}",
        "Arrebato de celular y pertenencias por sujetos en moto en {calle}",
        "Asalto a una vecina cerca del paradero en {calle}",
        "Robo con arma blanca a joven que retornaba a su domicilio en {calle}",
    ],
    "pandillaje": [
        "Grupo de jóvenes generando disturbios y amedrentando peatones en {calle}",
        "Enfrentamiento entre grupos callejeros con piedras en {calle}",
        "Disturbios y peleas al anochecer en la esquina de {calle}",
        "Pintas vandálicas y escándalo en {calle}",
    ],
    "alcohol_drogas": [
        "Sujetos consumiendo bebidas alcohólicas y sustancias en la vía pública de {calle}",
        "Personas bebiendo licor en la acera y bloqueando el paso en {calle}",
        "Consumo de drogas y botellas rotas frente a viviendas en {calle}",
        "Grupo libando y generando desorden vecinal en {calle}",
    ],
    "falta_alumbrado": [
        "Poste de alumbrado público inoperativo, dejando la cuadra a oscuras en {calle}",
        "Tramo sin iluminación pública por luminarias quemadas en {calle}",
        "Luminaria intermitente y zona muy oscura en horas de la noche en {calle}",
        "Falta total de alumbrado en pasaje peatonal de {calle}",
    ],
    "actividad_sospechosa": [
        "Vehículo estacionado con individuos observando viviendas sospechosamente en {calle}",
        "Persona encapuchada intentando forzar portones de garaje en {calle}",
        "Desconocidos merodeando de madrugada y observando entradas en {calle}",
        "Sujetos vigilando movimientos de vecinos en {calle}",
    ],
    "otro": [
        "Acumulación clandestina de desmonte y basura obstaculizando el tránsito en {calle}",
        "Jauría de canes agresivos sin correa en plena vía pública de {calle}",
        "Ruidos molestos y escándalo vecinal hasta altas horas de la madrugada en {calle}",
        "Buzón de desagüe sin tapa representando peligro peatonal en {calle}",
    ],
}

# Calles y vías reales de cada sector de Huancayo extraídas de OpenStreetMap (lat, lng, nombre)
CALLES_POR_BARRIO: dict[str, list[tuple[float, float, str]]] = {
    "b1": [
        (-12.055915, -75.188339, "Avenida Alameda"),
        (-12.04994, -75.186711, "Los Manzanos"),
        (-12.059898, -75.18412, "Avenida Via Integracion Este"),
        (-12.051155, -75.191902, "Pasaje Las Tunas"),
        (-12.054641, -75.183841, "Jirón Quishuar"),
        (-12.059327, -75.187983, "Avenida Circunvalacion"),
        (-12.052705, -75.189063, "Jirón Fénix"),
        (-12.05305, -75.18623, "Capitán Gutierrez Espinoza"),
        (-12.057238, -75.185863, "Pasaje Naranjillo"),
    ],
    "b2": [
        (-12.041659, -75.19009, "Avenida Universitaria"),
        (-12.03245, -75.196004, "Jirón Santa Rosa"),
        (-12.041898, -75.198319, "Calle José Santos Chocano"),
        (-12.034384, -75.190279, "Avenida Palián"),
        (-12.038004, -75.194621, "Psje. Colón (Palián)"),
        (-12.04382, -75.193888, "Jirón Venus"),
        (-12.038415, -75.187709, "Avenida Alameda Universitaria"),
        (-12.037225, -75.198148, "Calle Libra"),
        (-12.037867, -75.191197, "Jirón Los Álamos"),
        (-12.03257, -75.193029, "Calle José Olaya"),
        (-12.040707, -75.192891, "Calle El Sol"),
    ],
    "b3": [
        (-12.060295, -75.210387, "Avenida Ferrocarril"),
        (-12.057395, -75.196494, "Jirón Maypu"),
        (-12.070296, -75.201612, "Prolongación Huanuco"),
        (-12.051608, -75.20472, "Calle San Antonio"),
        (-12.062499, -75.202551, "Pasaje San Antonio"),
        (-12.057383, -75.205221, "Jirón Brasilia"),
        (-12.066542, -75.206373, "Avenida Giraldez"),
        (-12.054749, -75.200895, "Pasaje Santa Isabel"),
        (-12.065985, -75.199168, "Pasaje Santa Fe"),
        (-12.058942, -75.200392, "Pasaje Gerónimo da Silva"),
        (-12.062481, -75.20695, "Jirón Abancay"),
        (-12.065702, -75.202747, "Jirón San Francisco de Asis"),
        (-12.061868, -75.19954, "Avenida José Olaya"),
        (-12.069145, -75.204887, "Jirón Atahualpa"),
    ],
    "b4": [
        (-12.06631, -75.211672, "Calle Real"),
        (-12.072927, -75.203168, "Avenida Jacinto Ibarra"),
        (-12.075655, -75.213699, "Cajamarca"),
        (-12.072255, -75.209231, "Jirón Arequipa"),
        (-12.067529, -75.206311, "Jirón Pachitea"),
        (-12.070319, -75.215244, "Pasaje Morales"),
        (-12.063799, -75.208726, "Pasaje Culis"),
        (-12.074966, -75.206397, "Jirón Angaraez"),
        (-12.075921, -75.21023, "Jirón Tarapaca"),
        (-12.069578, -75.211938, "Avenida Paseo de la Breña"),
        (-12.069717, -75.203638, "Jirón Piura Antigua"),
        (-12.071563, -75.206033, "Jirón Mantaro"),
        (-12.068967, -75.208963, "Jirón Ancash"),
        (-12.072774, -75.212156, "Jirón Ica"),
        (-12.067986, -75.214523, "Jirón Ayacucho"),
    ],
    "b5": [
        (-12.073061, -75.198978, "Avenida Ocopilla"),
        (-12.062626, -75.181393, "Avenida Taylor"),
        (-12.057706, -75.196227, "Jirón Maypu"),
        (-12.069052, -75.18947, "Jirón Andres Avelino Caceres"),
        (-12.059025, -75.188517, "Calle 14 de Junio"),
        (-12.065662, -75.196499, "Circunvalacion"),
        (-12.074003, -75.192786, "Avenida Leoncio Prado"),
        (-12.063615, -75.191285, "Pasaje San Valentin"),
        (-12.064389, -75.185924, "Jirón Piura Antigua"),
        (-12.077585, -75.200404, "Avenida Jacinto Ibarra"),
        (-12.069983, -75.195425, "Jirón Inclán"),
        (-12.056377, -75.192136, "Jirón Chacabuco"),
    ],
    "b6": [
        (-12.072985, -75.216375, "Jirón Lima"),
        (-12.081178, -75.22793, "Jirón Ica Nueva"),
        (-12.075406, -75.223347, "Pasaje 14 de Julio"),
        (-12.079184, -75.218247, "Jirón Tarapaca"),
        (-12.080407, -75.22267, "Jirón Las Retamas"),
        (-12.077256, -75.22689, "Pasaje Uno"),
        (-12.073022, -75.220162, "Pasaje 5 de Octubre"),
        (-12.076663, -75.215524, "Cajamarca"),
        (-12.077425, -75.220835, "Pasaje Los Rosales"),
        (-12.079909, -75.225492, "Pasaje Carrión"),
    ],
    "b7": [
        (-12.052907, -75.199641, "Avenida Mártires del Periodismo"),
        (-12.043215, -75.196357, "Pasaje San Luis"),
        (-12.055833, -75.191405, "Jirón Chacabuco"),
        (-12.048658, -75.191801, "Calle Los Alamos"),
        (-12.047425, -75.200389, "Jirón San Pablo Miki"),
        (-12.051306, -75.204485, "Jirón San Santiago"),
        (-12.056369, -75.196224, "Calle C"),
        (-12.05185, -75.195133, "Avenida José Olaya"),
        (-12.047458, -75.196106, "Pasaje Samuel"),
        (-12.049927, -75.198104, "Jirón San Agustín"),
        (-12.050351, -75.201627, "Pasaje Progreso"),
        (-12.045454, -75.19831, "Jirón Santa María Goretti"),
        (-12.04522, -75.194339, "Pasaje Santa Cecilia"),
    ],
    "b8": [
        (-12.028523, -75.18622, "Calle Progreso"),
        (-12.028083, -75.196722, "Jirón El Sol"),
        (-12.036352, -75.189437, "Pasaje Las Flores"),
        (-12.02296, -75.190959, "San Luis"),
        (-12.031751, -75.192273, "Calle José de San Martín"),
        (-12.025132, -75.182535, "Avenida El Sol"),
        (-12.027243, -75.1918, "Avenida Agricultura"),
        (-12.024585, -75.186515, "Calle 2"),
        (-12.031215, -75.188639, "Jirón Los Álamos"),
        (-12.026656, -75.188721, "Calle Cantuta"),
        (-12.027673, -75.183543, "JIrón San Felipe"),
    ],
    "b9": [
        (-12.048414, -75.187325, "Los Robles"),
        (-12.048615, -75.194901, "Calle Las Orquideas"),
        (-12.044275, -75.191176, "Jirón Los Andes"),
        (-12.050504, -75.191092, "Los Fresnos"),
        (-12.045168, -75.187338, "Jirón Jhantu"),
        (-12.047378, -75.191496, "Calle El Paraiso"),
        (-12.047961, -75.189447, "Jirón Centauro"),
        (-12.04977, -75.188761, "Calle Alameda La Merced Sur"),
        (-12.045714, -75.190043, "Avenida Las Flores"),
        (-12.047335, -75.1933, "Calle Las Margaritas"),
    ],
}

# Tipos ponderados: los robos y el pandillaje generan más calor en el mapa.
TIPOS_REPORTE = [
    "asalto_robo",
    "asalto_robo",
    "pandillaje",
    "falta_alumbrado",
    "alcohol_drogas",
    "actividad_sospechosa",
    "otro",
]

# Rango de días de antigüedad (dias_desde, dias_hasta) por barrio para calor variado
PERFILES_TIEMPO = {
    "b1": (1, 14),   # Torre Torre
    "b2": (2, 25),   # Palián
    "b3": (0, 10),   # San Carlos
    "b4": (0, 7),    # Zona Monumental
    "b5": (1, 18),   # Ocopilla
    "b6": (3, 30),   # Cajas Chico
    "b7": (1, 12),   # San Antonio
    "b8": (2, 20),   # Uñas
    "b9": (4, 35),   # Chorrillos
}

CODIGOS_INICIALES = [
    ("c_b1", "b1", "TORRE-2026"),
    ("c_b2", "b2", "PALIAN-2026"),
    ("c_b3", "b3", "SANCARLOS-2026"),
    ("c_b4", "b4", "MONUMENTAL-2026"),
    ("c_b5", "b5", "OCOPILLA-2026"),
    ("c_b6", "b6", "CAJASCHICO-2026"),
    ("c_b7", "b7", "SANANTONIO-2026"),
    ("c_b8", "b8", "UNAS-2026"),
    ("c_b9", "b9", "CHORRILLOS-2026"),
]

SQL_USUARIO = """
    INSERT INTO usuarios
        (id, nombre, dni, correo, clave_hash, rol, id_barrio, estado, fecha_registro, institucion,
         strikes, suspendido_hasta, motivo_sancion)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    ON CONFLICT DO NOTHING
"""

SQL_REPORTE = """
    INSERT INTO reportes
        (id, id_usuario, id_barrio, lat, lng, tipo, gravedad, descripcion, fecha, estado)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    ON CONFLICT (id) DO NOTHING
"""

SQL_VOTO = """
    INSERT INTO votos_reporte (id_reporte, id_usuario, voto, fecha)
    VALUES (%s, %s, 'confirmo', %s)
    ON CONFLICT DO NOTHING
"""

SQL_INICIATIVA = """
    INSERT INTO iniciativas
        (id, id_barrio, id_creador, titulo, descripcion, meta, estado,
         temperatura_al_cumplir)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
    ON CONFLICT (id) DO NOTHING
"""

SQL_PARTICIPANTE = """
    INSERT INTO iniciativa_participantes (id_iniciativa, id_usuario)
    VALUES (%s, %s)
    ON CONFLICT DO NOTHING
"""

SQL_ACCION = """
    INSERT INTO acciones
        (id, id_barrio, id_autoridad, institucion, tipo, titulo, descripcion,
         fecha, estado, fotos, id_reporte, fecha_registro, temperatura_al_completar)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, '{}', NULL, %s, %s)
    ON CONFLICT (id) DO NOTHING
"""


def _tablas_vacias(conn: Connection) -> dict[str, bool]:
    """Indica qué tablas están vacías (con una sola consulta)."""
    fila = conn.execute(
        """
        SELECT NOT EXISTS (SELECT 1 FROM usuarios)       AS usuarios,
               NOT EXISTS (SELECT 1 FROM codigos_barrio) AS codigos_barrio,
               NOT EXISTS (SELECT 1 FROM reportes)       AS reportes,
               NOT EXISTS (SELECT 1 FROM iniciativas)    AS iniciativas,
               NOT EXISTS (SELECT 1 FROM acciones)       AS acciones
        """
    ).fetchone()
    return fila


def _cargar_codigos_barrio(conn: Connection) -> None:
    for id_cod, id_barrio, codigo in CODIGOS_INICIALES:
        conn.execute(
            """
            INSERT INTO codigos_barrio (id, id_barrio, codigo, activo, fecha_expiracion)
            VALUES (%s, %s, %s, TRUE, NULL)
            ON CONFLICT DO NOTHING
            """,
            (id_cod, id_barrio, codigo),
        )


def _vecinos(conn: Connection) -> list[dict]:
    """Ids y barrios de los vecinos, en orden natural (v1, v2, ..., v36)."""
    return conn.execute(
        "SELECT id, id_barrio FROM usuarios WHERE rol = 'vecino' ORDER BY length(id), id"
    ).fetchall()


def _cargar_usuarios(conn: Connection, ahora: datetime, barrios: list[Barrio]) -> None:
    clave = hashear("123456")
    filas: list[tuple] = []

    # Tres vecinos verificados por barrio (36 en total). El primero es el de la demo.
    for i, nombre in enumerate(NOMBRES):
        filas.append(
            (
                f"v{i + 1}",
                nombre,
                f"400000{i + 1:02d}",
                "vecino@barrio.com" if i == 0 else f"vecino{i + 1}@radar.pe",
                clave,
                "vecino",
                barrios[i % len(barrios)].id,
                "Verificado",
                ahora - timedelta(days=60),
                None,
                0,
                None,
                None,
            )
        )

    # Vecinos pendientes: la Municipalidad debe aprobarlos o rechazarlos.
    pendientes = [
        ("Miguel Arias", "b4"),
        ("Gloria Palacios", "b7"),
        ("Hugo Salazar", "b6"),
        ("Rita Campos", "b2"),
    ]
    for i, (nombre, id_barrio) in enumerate(pendientes, start=1):
        filas.append(
            (
                f"v{len(NOMBRES) + i}",
                nombre,
                f"400000{len(NOMBRES) + i:02d}",
                f"pendiente{i}@radar.pe",
                clave,
                "vecino",
                id_barrio,
                "Pendiente",
                ahora - timedelta(days=i),
                None,
                0,
                None,
                None,
            )
        )

    # Segundo actor: la Municipalidad.
    filas.append(
        (
            "m1",
            "Gerencia de Seguridad Ciudadana",
            "00000001",
            "muni@huancayo.gob.pe",
            clave,
            "municipalidad",
            None,
            "Verificado",
            ahora - timedelta(days=90),
            "Municipalidad",
            0,
            None,
            None,
        )
    )

    with conn.cursor() as cursor:
        cursor.executemany(SQL_USUARIO, filas)


def _cargar_reportes(conn: Connection, ahora: datetime, barrios: list[Barrio]) -> int:
    """Inserta 105 reportes distribuidos sobre calles reales de OpenStreetMap para los 9 barrios."""
    vecinos = _vecinos(conn)
    todos = [u["id"] for u in vecinos]
    contador = 0

    if not todos:
        logger.warning("No hay vecinos para asignar reportes de demostración.")
        return contador

    for bi, barrio in enumerate(barrios):
        autores = [u["id"] for u in vecinos if u["id_barrio"] == barrio.id] or todos
        votantes = [u for u in todos if u not in autores] or todos
        puntos = CALLES_POR_BARRIO.get(barrio.id, [])
        dias_desde, dias_hasta = PERFILES_TIEMPO.get(barrio.id, (1, 15))
        rango_dias = max(1, dias_hasta - dias_desde + 1)

        for i, (lat, lng, calle) in enumerate(puntos):
            tipo = TIPOS_REPORTE[(i * 3 + bi) % len(TIPOS_REPORTE)]
            plantillas = PLANTILLAS_POR_TIPO[tipo]
            descripcion = plantillas[(i + bi) % len(plantillas)].format(calle=calle)

            confirmaciones = (i * 2 + bi) % 4
            if barrio.id in ("b3", "b4") and i % 3 == 0:
                confirmaciones = 3
            estado = "confirmado" if confirmaciones >= 3 else "activo"

            dias = dias_desde + ((i * 13 + bi * 7) % rango_dias)
            horas = (i * 5 + bi * 3) % 24
            fecha = ahora - timedelta(days=dias, hours=horas, minutes=(i * 17) % 60)

            contador += 1
            id_reporte = f"r{contador}"
            conn.execute(
                SQL_REPORTE,
                (
                    id_reporte,
                    autores[i % len(autores)],
                    barrio.id,
                    lat,
                    lng,
                    tipo,
                    GRAVEDAD[tipo],
                    descripcion,
                    fecha,
                    estado,
                ),
            )
            for j in range(confirmaciones):
                conn.execute(
                    SQL_VOTO,
                    (
                        id_reporte,
                        votantes[(i + j + bi * 4) % len(votantes)],
                        fecha + timedelta(hours=j + 1, minutes=15),
                    ),
                )
    return contador


def _cargar_iniciativas(conn: Connection) -> None:
    datos = [
        ("i1", "b1", "v1", "Ronda vecinal nocturna", "Turnos de vigilancia los fines de semana.", "20 vecinos inscritos", "En curso", 14, None),
        ("i2", "b2", "v2", "Pedido de alumbrado", "Solicitud formal de reparación de postes.", "100 firmas", "Cumplida", 112, 6.2),
        ("i3", "b3", "v3", "Alarma comunitaria", "Instalar alarma con botón en 10 casas.", "S/ 1500 recaudados", "Propuesta", 5, None),
        ("i4", "b2", "v7", "Recuperación del parque", "Limpieza y actividades deportivas.", "3 jornadas", "En curso", 30, None),
        ("i5", "b1", "v6", "Cámaras vecinales", "Propuesta descartada por presupuesto.", "4 cámaras", "Cancelada", 8, None),
        ("i6", "b4", "v10", "Luz para Zona Monumental", "Cambio de luminarias en las calles altas.", "15 postes", "En curso", 27, None),
        ("i7", "b6", "v18", "Vecinos en alerta", "Red de mensajes para avisos inmediatos.", "60 vecinos", "Propuesta", 12, None),
        ("i8", "b7", "v21", "Cancha segura", "Recuperar la losa deportiva y cerrarla de noche.", "1 losa", "En curso", 41, None),
        ("i9", "b8", "v24", "Botones de pánico", "Instalar botones en las esquinas con más robos.", "6 botones", "Propuesta", 9, None),
        ("i10", "b9", "v27", "Huertos comunitarios", "Convertir un terreno baldío en huerto vecinal.", "1 terreno", "En curso", 23, None),
        ("i11", "b6", "v30", "Muro y luces", "Cerrar el pasaje oscuro y colocar reflectores.", "80 metros", "Propuesta", 7, None),
        ("i12", "b7", "v33", "Campaña de valores", "Talleres de convivencia para jóvenes.", "4 talleres", "Cumplida", 64, 12.8),
        ("i13", "b9", "v36", "Jornada de limpieza", "Retirar basura acumulada en la quebrada.", "2 jornadas", "En curso", 35, None),
        ("i14", "b5", "v15", "Feria de seguridad", "Feria informativa con Serenazgo y Policía.", "1 feria", "Cumplida", 90, 8.1),
        ("i15", "b3", "v9", "Veredas iluminadas", "Mejorar veredas y alumbrado del ingreso.", "300 metros", "Propuesta", 18, None),
        ("i16", "b1", "v3", "Directorio de emergencia", "Directorio de contactos útiles por manzana.", "1 directorio", "Cumplida", 48, 4.4),
    ]  # fmt: skip

    vecinos = [u["id"] for u in _vecinos(conn)]
    for id_, barrio, creador, titulo, descripcion, meta, estado, participantes, temp in datos:
        conn.execute(
            SQL_INICIATIVA,
            (id_, barrio, creador, titulo, descripcion, meta, estado, temp),
        )
        # `participantes` se cuenta desde la tabla puente. Solo hay 36 vecinos, así que
        # los conteos de la demo se limitan a los participantes disponibles.
        for id_vecino in vecinos[:participantes]:
            conn.execute(SQL_PARTICIPANTE, (id_, id_vecino))


def _cargar_acciones(conn: Connection, ahora: datetime) -> None:
    datos = [
        ("a1", "b1", "m1", "Municipalidad", "Patrullaje de serenazgo", "Patrullaje reforzado", "Se incrementaron rondas de 18:00 a 02:00.", -2, "En ejecución", None),
        ("a2", "b1", "m1", "Municipalidad", "Alumbrado", "Reparación de postes", "Se cambiaron 12 luminarias LED.", -6, "Completada", 9.1),
        ("a3", "b2", "m1", "Municipalidad", "Otro", "Limpieza de terreno baldío", "Retiro de maleza y desmonte.", 3, "Planificada", None),
        ("a4", "b3", "m1", "Municipalidad", "Patrullaje de serenazgo", "Punto fijo de serenazgo", "Unidad fija en la esquina del parque.", -1, "En ejecución", None),
        ("a5", "b4", "m1", "Municipalidad", "Otro", "Instalación de cámara", "Cámara conectada a la central.", -15, "Completada", 8.4),
        ("a6", "b5", "m1", "Municipalidad", "Campaña de prevención", "Charla de prevención", "Taller con las juntas vecinales.", 7, "Planificada", None),
        ("a7", "b6", "m1", "Municipalidad", "Patrullaje de serenazgo", "Patrullaje disuasivo en Cajas Chico", "Rondas por las calles principales del sector.", -4, "En ejecución", None),
        ("a8", "b7", "m1", "Municipalidad", "Alumbrado", "Reposición de luminarias en San Antonio", "Se repusieron 18 luminarias LED.", -9, "Completada", 26.4),
        ("a9", "b9", "m1", "Municipalidad", "Campaña de prevención", "Feria de seguridad vecinal", "Feria informativa en la plaza del barrio.", 5, "Planificada", None),
        ("a10", "b6", "m1", "Municipalidad", "Alumbrado", "Ampliación de red eléctrica", "Nuevos postes en el pasaje alto.", 8, "Planificada", None),
        ("a11", "b9", "m1", "Municipalidad", "Otro", "Mantenimiento de cámaras", "Se repararon las cámaras de la avenida.", -20, "Completada", 41.2),
        ("a12", "b5", "m1", "Municipalidad", "Patrullaje de serenazgo", "Refuerzo de vigilancia", "Patrulla adicional los fines de semana.", -2, "En ejecución", None),
        ("a13", "b3", "m1", "Municipalidad", "Alumbrado", "Cambio de 20 luminarias", "Intervención completa en el sector.", -5, "Completada", 21.7),
        ("a14", "b1", "m1", "Municipalidad", "Operativo con la policía", "Control de identidad", "Operativo conjunto en la avenida principal.", -8, "Completada", 14.3),
        ("a15", "b2", "m1", "Municipalidad", "Campaña de prevención", "Taller para juntas vecinales", "Capacitación sobre rutas de denuncia.", 10, "Planificada", None),
        ("a16", "b4", "m1", "Municipalidad", "Alumbrado", "Reparación de poste averiado", "El poste de la esquina ya está operativo.", -3, "En ejecución", None),
        ("a17", "b8", "m1", "Municipalidad", "Operativo con la policía", "Operativo en Uñas", "Patrullaje conjunto en zonas críticas.", 2, "Planificada", None),
        ("a18", "b8", "m1", "Municipalidad", "Otro", "Señalización de calles", "Nuevos letreros y señalética peatonal.", 12, "Planificada", None),
    ]  # fmt: skip
    for id_, barrio, autoridad, institucion, tipo, titulo, descripcion, dias, estado, temp in datos:
        fecha = ahora + timedelta(days=dias)
        # `fecha_registro` se iguala a `fecha` (como en la demo original, donde era nula).
        conn.execute(
            SQL_ACCION,
            (
                id_,
                barrio,
                autoridad,
                institucion,
                tipo,
                titulo,
                descripcion,
                fecha,
                estado,
                fecha,
                temp,
            ),
        )

    # Algunas acciones responden a un reporte concreto: el vecino ve la respuesta en su reporte.
    respuestas = {
        "a1": "b1",
        "a4": "b3",
        "a7": "b6",
        "a12": "b5",
        "a16": "b4",
        "a17": "b8",
    }
    for id_accion, id_barrio in respuestas.items():
        reporte = conn.execute(
            """
            SELECT id FROM reportes
             WHERE id_barrio = %s AND estado <> 'archivado'
             ORDER BY fecha DESC
             LIMIT 1
            """,
            (id_barrio,),
        ).fetchone()
        if reporte:
            conn.execute(
                "UPDATE acciones SET id_reporte = %s WHERE id = %s",
                (reporte["id"], id_accion),
            )


def cargar_datos_iniciales() -> None:
    """Inserta la demo únicamente en las tablas que estén vacías (idempotente)."""
    ahora = datetime.now(UTC)
    with pool.connection() as conn:
        barrios = barrio_repository.list(conn=conn)
        if not barrios:
            raise RuntimeError(
                "La tabla 'barrios' está vacía. Ejecuta db/schema.sql y carga los 9 barrios."
            )

        vacias = _tablas_vacias(conn)
        if vacias["codigos_barrio"]:
            _cargar_codigos_barrio(conn)
            logger.info("Datos demo: códigos de acceso por barrio insertados")
        if vacias["usuarios"]:
            _cargar_usuarios(conn, ahora, barrios)
            logger.info("Datos demo: usuarios y cuentas insertados")
        if vacias["reportes"]:
            reportes = _cargar_reportes(conn, ahora, barrios)
            logger.info("Datos demo: %s reportes con votos insertados", reportes)
        if vacias["iniciativas"]:
            _cargar_iniciativas(conn)
            logger.info("Datos demo: iniciativas y participantes insertados")
        if vacias["acciones"]:
            _cargar_acciones(conn, ahora)
            logger.info("Datos demo: acciones municipales insertadas")
