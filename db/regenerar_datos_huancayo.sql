-- =====================================================================
-- Radar Vecinal · Regeneración Total de Reportes con Calles Reales de OSM
-- Distritos/Sectores: 9 barrios de Huancayo (b1 a b9)
-- Coordenadas sobre calzadas reales obtenidas de OpenStreetMap
-- =====================================================================

BEGIN;

-- 1. Desvincular acciones de reportes demo anteriores
UPDATE public.acciones SET id_reporte = NULL;

-- 2. Limpiar votos, denuncias y reportes anteriores
DELETE FROM public.votos_reporte;
DELETE FROM public.denuncias_reporte;
DELETE FROM public.reportes;

-- 3. Actualizar títulos de iniciativas y acciones con nombres de sectores actuales
UPDATE public.iniciativas SET titulo = 'Luz para Zona Monumental' WHERE id = 'i6';
UPDATE public.acciones SET titulo = 'Patrullaje disuasivo en Cajas Chico' WHERE id = 'a7';
UPDATE public.acciones SET titulo = 'Reposición de luminarias en San Antonio' WHERE id = 'a8';
UPDATE public.acciones SET titulo = 'Operativo en Uñas' WHERE id = 'a17';

-- 4. Insertar los 105 nuevos reportes sobre calles reales
INSERT INTO public.reportes (id, id_usuario, id_barrio, lat, lng, tipo, gravedad, descripcion, fecha, estado) VALUES
  ('r1', 'v1', 'b1', -12.055915, -75.188339, 'asalto_robo', 5, 'Robo al paso a mano armada a transeúnte en Avenida Alameda', '2026-11-22T13:00:00+00:00', 'activo'),
  ('r2', 'v10', 'b1', -12.04994, -75.186711, 'falta_alumbrado', 2, 'Tramo sin iluminación pública por luminarias quemadas en Los Manzanos', '2026-11-09T07:43:00+00:00', 'activo'),
  ('r3', 'v19', 'b1', -12.059898, -75.18412, 'otro', 1, 'Ruidos molestos y escándalo vecinal hasta altas horas de la madrugada en Avenida Via Integracion Este', '2026-11-10T02:26:00+00:00', 'activo'),
  ('r4', 'v28', 'b1', -12.051155, -75.191902, 'pandillaje', 3, 'Pintas vandálicas y escándalo en Pasaje Las Tunas', '2026-11-10T21:09:00+00:00', 'activo'),
  ('r5', 'v1', 'b1', -12.054641, -75.183841, 'actividad_sospechosa', 1, 'Vehículo estacionado con individuos observando viviendas sospechosamente en Jirón Quishuar', '2026-11-11T16:52:00+00:00', 'activo'),
  ('r6', 'v10', 'b1', -12.059327, -75.187983, 'asalto_robo', 5, 'Arrebato de celular y pertenencias por sujetos en moto en Avenida Circunvalacion', '2026-11-13T11:35:00+00:00', 'activo'),
  ('r7', 'v19', 'b1', -12.052705, -75.189063, 'alcohol_drogas', 3, 'Consumo de drogas y botellas rotas frente a viviendas en Jirón Fénix', '2026-11-14T06:18:00+00:00', 'activo'),
  ('r8', 'v28', 'b1', -12.05305, -75.18623, 'asalto_robo', 5, 'Robo con arma blanca a joven que retornaba a su domicilio en Capitán Gutierrez Espinoza', '2026-11-15T01:01:00+00:00', 'activo'),
  ('r9', 'v1', 'b1', -12.057238, -75.185863, 'falta_alumbrado', 2, 'Poste de alumbrado público inoperativo, dejando la cuadra a oscuras en Pasaje Naranjillo', '2026-11-15T20:44:00+00:00', 'activo'),
  ('r10', 'v2', 'b2', -12.041659, -75.19009, 'asalto_robo', 5, 'Arrebato de celular y pertenencias por sujetos en moto en Avenida Universitaria', '2026-11-14T10:00:00+00:00', 'activo'),
  ('r11', 'v11', 'b2', -12.03245, -75.196004, 'alcohol_drogas', 3, 'Consumo de drogas y botellas rotas frente a viviendas en Jirón Santa Rosa', '2026-11-01T04:43:00+00:00', 'confirmado'),
  ('r12', 'v20', 'b2', -12.041898, -75.198319, 'asalto_robo', 5, 'Robo con arma blanca a joven que retornaba a su domicilio en Calle José Santos Chocano', '2026-11-11T23:26:00+00:00', 'activo'),
  ('r13', 'v29', 'b2', -12.034384, -75.190279, 'falta_alumbrado', 2, 'Poste de alumbrado público inoperativo, dejando la cuadra a oscuras en Avenida Palián', '2026-10-29T18:09:00+00:00', 'confirmado'),
  ('r14', 'v2', 'b2', -12.038004, -75.194621, 'otro', 1, 'Jauría de canes agresivos sin correa en plena vía pública de Psje. Colón (Palián)', '2026-11-09T13:52:00+00:00', 'activo'),
  ('r15', 'v11', 'b2', -12.04382, -75.193888, 'pandillaje', 3, 'Disturbios y peleas al anochecer en la esquina de Jirón Venus', '2026-11-21T08:35:00+00:00', 'confirmado'),
  ('r16', 'v20', 'b2', -12.038415, -75.187709, 'actividad_sospechosa', 1, 'Sujetos vigilando movimientos de vecinos en Avenida Alameda Universitaria', '2026-11-08T03:18:00+00:00', 'activo'),
  ('r17', 'v29', 'b2', -12.037225, -75.198148, 'asalto_robo', 5, 'Robo al paso a mano armada a transeúnte en Calle Libra', '2026-11-18T22:01:00+00:00', 'confirmado'),
  ('r18', 'v2', 'b2', -12.037867, -75.191197, 'alcohol_drogas', 3, 'Personas bebiendo licor en la acera y bloqueando el paso en Jirón Los Álamos', '2026-11-05T17:44:00+00:00', 'activo'),
  ('r19', 'v11', 'b2', -12.03257, -75.193029, 'asalto_robo', 5, 'Asalto a una vecina cerca del paradero en Calle José Olaya', '2026-11-17T12:27:00+00:00', 'confirmado'),
  ('r20', 'v20', 'b2', -12.040707, -75.192891, 'falta_alumbrado', 2, 'Falta total de alumbrado en pasaje peatonal de Calle El Sol', '2026-11-04T07:10:00+00:00', 'activo'),
  ('r21', 'v3', 'b3', -12.060295, -75.210387, 'pandillaje', 3, 'Disturbios y peleas al anochecer en la esquina de Avenida Ferrocarril', '2026-11-20T07:00:00+00:00', 'confirmado'),
  ('r22', 'v12', 'b3', -12.057395, -75.196494, 'actividad_sospechosa', 1, 'Sujetos vigilando movimientos de vecinos en Jirón Maypu', '2026-11-18T01:43:00+00:00', 'activo'),
  ('r23', 'v21', 'b3', -12.070296, -75.201612, 'asalto_robo', 5, 'Robo al paso a mano armada a transeúnte en Prolongación Huanuco', '2026-11-15T20:26:00+00:00', 'activo'),
  ('r24', 'v30', 'b3', -12.051608, -75.20472, 'alcohol_drogas', 3, 'Personas bebiendo licor en la acera y bloqueando el paso en Calle San Antonio', '2026-11-13T15:09:00+00:00', 'confirmado'),
  ('r25', 'v3', 'b3', -12.062499, -75.202551, 'asalto_robo', 5, 'Asalto a una vecina cerca del paradero en Pasaje San Antonio', '2026-11-23T10:52:00+00:00', 'activo'),
  ('r26', 'v12', 'b3', -12.057383, -75.205221, 'falta_alumbrado', 2, 'Falta total de alumbrado en pasaje peatonal de Jirón Brasilia', '2026-11-21T05:35:00+00:00', 'activo'),
  ('r27', 'v21', 'b3', -12.066542, -75.206373, 'otro', 1, 'Acumulación clandestina de desmonte y basura obstaculizando el tránsito en Avenida Giraldez', '2026-11-19T00:18:00+00:00', 'confirmado'),
  ('r28', 'v30', 'b3', -12.054749, -75.200895, 'pandillaje', 3, 'Enfrentamiento entre grupos callejeros con piedras en Pasaje Santa Isabel', '2026-11-16T19:01:00+00:00', 'activo'),
  ('r29', 'v3', 'b3', -12.065985, -75.199168, 'actividad_sospechosa', 1, 'Desconocidos merodeando de madrugada y observando entradas en Pasaje Santa Fe', '2026-11-14T14:44:00+00:00', 'activo'),
  ('r30', 'v12', 'b3', -12.058942, -75.200392, 'asalto_robo', 5, 'Robo con arma blanca a joven que retornaba a su domicilio en Pasaje Gerónimo da Silva', '2026-11-13T09:27:00+00:00', 'confirmado'),
  ('r31', 'v21', 'b3', -12.062481, -75.20695, 'alcohol_drogas', 3, 'Sujetos consumiendo bebidas alcohólicas y sustancias en la vía pública de Jirón Abancay', '2026-11-22T04:10:00+00:00', 'activo'),
  ('r32', 'v30', 'b3', -12.065702, -75.202747, 'asalto_robo', 5, 'Arrebato de celular y pertenencias por sujetos en moto en Jirón San Francisco de Asis', '2026-11-19T23:53:00+00:00', 'activo'),
  ('r33', 'v3', 'b3', -12.061868, -75.19954, 'falta_alumbrado', 2, 'Luminaria intermitente y zona muy oscura en horas de la noche en Avenida José Olaya', '2026-11-17T18:36:00+00:00', 'confirmado'),
  ('r34', 'v12', 'b3', -12.069145, -75.204887, 'otro', 1, 'Buzón de desagüe sin tapa representando peligro peatonal en Jirón Atahualpa', '2026-11-15T13:19:00+00:00', 'activo'),
  ('r35', 'v4', 'b4', -12.06631, -75.211672, 'falta_alumbrado', 2, 'Falta total de alumbrado en pasaje peatonal de Calle Real', '2026-11-18T04:00:00+00:00', 'confirmado'),
  ('r36', 'v13', 'b4', -12.072927, -75.203168, 'otro', 1, 'Acumulación clandestina de desmonte y basura obstaculizando el tránsito en Avenida Jacinto Ibarra', '2026-11-20T22:43:00+00:00', 'activo'),
  ('r37', 'v22', 'b4', -12.075655, -75.213699, 'pandillaje', 3, 'Enfrentamiento entre grupos callejeros con piedras en Cajamarca', '2026-11-15T17:26:00+00:00', 'confirmado'),
  ('r38', 'v31', 'b4', -12.072255, -75.209231, 'actividad_sospechosa', 1, 'Desconocidos merodeando de madrugada y observando entradas en Jirón Arequipa', '2026-11-19T12:09:00+00:00', 'confirmado'),
  ('r39', 'v4', 'b4', -12.067529, -75.206311, 'asalto_robo', 5, 'Robo con arma blanca a joven que retornaba a su domicilio en Jirón Pachitea', '2026-11-22T07:52:00+00:00', 'confirmado'),
  ('r40', 'v13', 'b4', -12.070319, -75.215244, 'alcohol_drogas', 3, 'Sujetos consumiendo bebidas alcohólicas y sustancias en la vía pública de Pasaje Morales', '2026-11-17T02:35:00+00:00', 'activo'),
  ('r41', 'v22', 'b4', -12.063799, -75.208726, 'asalto_robo', 5, 'Arrebato de celular y pertenencias por sujetos en moto en Pasaje Culis', '2026-11-19T21:18:00+00:00', 'confirmado'),
  ('r42', 'v31', 'b4', -12.074966, -75.206397, 'falta_alumbrado', 2, 'Luminaria intermitente y zona muy oscura en horas de la noche en Jirón Angaraez', '2026-11-22T16:01:00+00:00', 'activo'),
  ('r43', 'v4', 'b4', -12.075921, -75.21023, 'otro', 1, 'Buzón de desagüe sin tapa representando peligro peatonal en Jirón Tarapaca', '2026-11-18T11:44:00+00:00', 'confirmado'),
  ('r44', 'v13', 'b4', -12.069578, -75.211938, 'pandillaje', 3, 'Grupo de jóvenes generando disturbios y amedrentando peatones en Avenida Paseo de la Breña', '2026-11-21T06:27:00+00:00', 'confirmado'),
  ('r45', 'v22', 'b4', -12.069717, -75.203638, 'actividad_sospechosa', 1, 'Persona encapuchada intentando forzar portones de garaje en Jirón Piura Antigua', '2026-11-16T01:10:00+00:00', 'confirmado'),
  ('r46', 'v31', 'b4', -12.071563, -75.206033, 'asalto_robo', 5, 'Asalto a una vecina cerca del paradero en Jirón Mantaro', '2026-11-18T20:53:00+00:00', 'activo'),
  ('r47', 'v4', 'b4', -12.068967, -75.208963, 'alcohol_drogas', 3, 'Grupo libando y generando desorden vecinal en Jirón Ancash', '2026-11-21T15:36:00+00:00', 'confirmado'),
  ('r48', 'v13', 'b4', -12.072774, -75.212156, 'asalto_robo', 5, 'Robo al paso a mano armada a transeúnte en Jirón Ica', '2026-11-17T10:19:00+00:00', 'activo'),
  ('r49', 'v22', 'b4', -12.067986, -75.214523, 'falta_alumbrado', 2, 'Tramo sin iluminación pública por luminarias quemadas en Jirón Ayacucho', '2026-11-20T05:02:00+00:00', 'confirmado'),
  ('r50', 'v5', 'b5', -12.073061, -75.198978, 'alcohol_drogas', 3, 'Sujetos consumiendo bebidas alcohólicas y sustancias en la vía pública de Avenida Ocopilla', '2026-11-12T01:00:00+00:00', 'activo'),
  ('r51', 'v14', 'b5', -12.062626, -75.181393, 'asalto_robo', 5, 'Arrebato de celular y pertenencias por sujetos en moto en Avenida Taylor', '2026-11-16T19:43:00+00:00', 'activo'),
  ('r52', 'v23', 'b5', -12.057706, -75.196227, 'falta_alumbrado', 2, 'Luminaria intermitente y zona muy oscura en horas de la noche en Jirón Maypu', '2026-11-21T14:26:00+00:00', 'activo'),
  ('r53', 'v32', 'b5', -12.069052, -75.18947, 'otro', 1, 'Buzón de desagüe sin tapa representando peligro peatonal en Jirón Andres Avelino Caceres', '2026-11-09T09:09:00+00:00', 'activo'),
  ('r54', 'v5', 'b5', -12.059025, -75.188517, 'pandillaje', 3, 'Grupo de jóvenes generando disturbios y amedrentando peatones en Calle 14 de Junio', '2026-11-14T04:52:00+00:00', 'activo'),
  ('r55', 'v14', 'b5', -12.065662, -75.196499, 'actividad_sospechosa', 1, 'Persona encapuchada intentando forzar portones de garaje en Circunvalacion', '2026-11-18T23:35:00+00:00', 'activo'),
  ('r56', 'v23', 'b5', -12.074003, -75.192786, 'asalto_robo', 5, 'Asalto a una vecina cerca del paradero en Avenida Leoncio Prado', '2026-11-05T18:18:00+00:00', 'activo'),
  ('r57', 'v32', 'b5', -12.063615, -75.191285, 'alcohol_drogas', 3, 'Grupo libando y generando desorden vecinal en Pasaje San Valentin', '2026-11-10T13:01:00+00:00', 'activo'),
  ('r58', 'v5', 'b5', -12.064389, -75.185924, 'asalto_robo', 5, 'Robo al paso a mano armada a transeúnte en Jirón Piura Antigua', '2026-11-16T08:44:00+00:00', 'activo'),
  ('r59', 'v14', 'b5', -12.077585, -75.200404, 'falta_alumbrado', 2, 'Tramo sin iluminación pública por luminarias quemadas en Avenida Jacinto Ibarra', '2026-11-21T03:27:00+00:00', 'activo'),
  ('r60', 'v23', 'b5', -12.069983, -75.195425, 'otro', 1, 'Ruidos molestos y escándalo vecinal hasta altas horas de la madrugada en Jirón Inclán', '2026-11-07T22:10:00+00:00', 'activo'),
  ('r61', 'v32', 'b5', -12.056377, -75.192136, 'pandillaje', 3, 'Pintas vandálicas y escándalo en Jirón Chacabuco', '2026-11-12T17:53:00+00:00', 'activo'),
  ('r62', 'v6', 'b6', -12.072985, -75.216375, 'actividad_sospechosa', 1, 'Persona encapuchada intentando forzar portones de garaje en Jirón Lima', '2026-11-12T22:00:00+00:00', 'activo'),
  ('r63', 'v15', 'b6', -12.081178, -75.22793, 'asalto_robo', 5, 'Asalto a una vecina cerca del paradero en Jirón Ica Nueva', '2026-10-30T16:43:00+00:00', 'confirmado'),
  ('r64', 'v24', 'b6', -12.075406, -75.223347, 'alcohol_drogas', 3, 'Grupo libando y generando desorden vecinal en Pasaje 14 de Julio', '2026-11-15T11:26:00+00:00', 'activo'),
  ('r65', 'v33', 'b6', -12.079184, -75.218247, 'asalto_robo', 5, 'Robo al paso a mano armada a transeúnte en Jirón Tarapaca', '2026-11-02T06:09:00+00:00', 'confirmado'),
  ('r66', 'v6', 'b6', -12.080407, -75.22267, 'falta_alumbrado', 2, 'Tramo sin iluminación pública por luminarias quemadas en Jirón Las Retamas', '2026-11-17T01:52:00+00:00', 'activo'),
  ('r67', 'v15', 'b6', -12.077256, -75.22689, 'otro', 1, 'Ruidos molestos y escándalo vecinal hasta altas horas de la madrugada en Pasaje Uno', '2026-11-03T20:35:00+00:00', 'confirmado'),
  ('r68', 'v24', 'b6', -12.073022, -75.220162, 'pandillaje', 3, 'Pintas vandálicas y escándalo en Pasaje 5 de Octubre', '2026-11-18T15:18:00+00:00', 'activo'),
  ('r69', 'v33', 'b6', -12.076663, -75.215524, 'actividad_sospechosa', 1, 'Vehículo estacionado con individuos observando viviendas sospechosamente en Cajamarca', '2026-11-06T10:01:00+00:00', 'confirmado'),
  ('r70', 'v6', 'b6', -12.077425, -75.220835, 'asalto_robo', 5, 'Arrebato de celular y pertenencias por sujetos en moto en Pasaje Los Rosales', '2026-10-24T05:44:00+00:00', 'activo'),
  ('r71', 'v15', 'b6', -12.079909, -75.225492, 'alcohol_drogas', 3, 'Consumo de drogas y botellas rotas frente a viviendas en Pasaje Carrión', '2026-11-08T00:27:00+00:00', 'confirmado'),
  ('r72', 'v7', 'b7', -12.052907, -75.199641, 'otro', 1, 'Ruidos molestos y escándalo vecinal hasta altas horas de la madrugada en Avenida Mártires del Periodismo', '2026-11-15T19:00:00+00:00', 'activo'),
  ('r73', 'v16', 'b7', -12.043215, -75.196357, 'pandillaje', 3, 'Pintas vandálicas y escándalo en Pasaje San Luis', '2026-11-14T13:43:00+00:00', 'activo'),
  ('r74', 'v25', 'b7', -12.055833, -75.191405, 'actividad_sospechosa', 1, 'Vehículo estacionado con individuos observando viviendas sospechosamente en Jirón Chacabuco', '2026-11-14T08:26:00+00:00', 'activo'),
  ('r75', 'v34', 'b7', -12.048658, -75.191801, 'asalto_robo', 5, 'Arrebato de celular y pertenencias por sujetos en moto en Calle Los Alamos', '2026-11-13T03:09:00+00:00', 'activo'),
  ('r76', 'v7', 'b7', -12.047425, -75.200389, 'alcohol_drogas', 3, 'Consumo de drogas y botellas rotas frente a viviendas en Jirón San Pablo Miki', '2026-11-11T22:52:00+00:00', 'activo'),
  ('r77', 'v16', 'b7', -12.051306, -75.204485, 'asalto_robo', 5, 'Robo con arma blanca a joven que retornaba a su domicilio en Jirón San Santiago', '2026-11-10T17:35:00+00:00', 'activo'),
  ('r78', 'v25', 'b7', -12.056369, -75.196224, 'falta_alumbrado', 2, 'Poste de alumbrado público inoperativo, dejando la cuadra a oscuras en Calle C', '2026-11-22T12:18:00+00:00', 'activo'),
  ('r79', 'v34', 'b7', -12.05185, -75.195133, 'otro', 1, 'Jauría de canes agresivos sin correa en plena vía pública de Avenida José Olaya', '2026-11-21T07:01:00+00:00', 'activo'),
  ('r80', 'v7', 'b7', -12.047458, -75.196106, 'pandillaje', 3, 'Disturbios y peleas al anochecer en la esquina de Pasaje Samuel', '2026-11-20T02:44:00+00:00', 'activo'),
  ('r81', 'v16', 'b7', -12.049927, -75.198104, 'actividad_sospechosa', 1, 'Sujetos vigilando movimientos de vecinos en Jirón San Agustín', '2026-11-18T21:27:00+00:00', 'activo'),
  ('r82', 'v25', 'b7', -12.050351, -75.201627, 'asalto_robo', 5, 'Robo al paso a mano armada a transeúnte en Pasaje Progreso', '2026-11-17T16:10:00+00:00', 'activo'),
  ('r83', 'v34', 'b7', -12.045454, -75.19831, 'alcohol_drogas', 3, 'Personas bebiendo licor en la acera y bloqueando el paso en Jirón Santa María Goretti', '2026-11-17T11:53:00+00:00', 'activo'),
  ('r84', 'v7', 'b7', -12.04522, -75.194339, 'asalto_robo', 5, 'Asalto a una vecina cerca del paradero en Pasaje Santa Cecilia', '2026-11-16T06:36:00+00:00', 'activo'),
  ('r85', 'v8', 'b8', -12.028523, -75.18622, 'asalto_robo', 5, 'Robo con arma blanca a joven que retornaba a su domicilio en Calle Progreso', '2026-11-09T16:00:00+00:00', 'confirmado'),
  ('r86', 'v17', 'b8', -12.028083, -75.196722, 'falta_alumbrado', 2, 'Poste de alumbrado público inoperativo, dejando la cuadra a oscuras en Jirón El Sol', '2026-11-16T10:43:00+00:00', 'activo'),
  ('r87', 'v26', 'b8', -12.036352, -75.189437, 'otro', 1, 'Jauría de canes agresivos sin correa en plena vía pública de Pasaje Las Flores', '2026-11-03T05:26:00+00:00', 'confirmado'),
  ('r88', 'v35', 'b8', -12.02296, -75.190959, 'pandillaje', 3, 'Disturbios y peleas al anochecer en la esquina de San Luis', '2026-11-09T00:09:00+00:00', 'activo'),
  ('r89', 'v8', 'b8', -12.031751, -75.192273, 'actividad_sospechosa', 1, 'Sujetos vigilando movimientos de vecinos en Calle José de San Martín', '2026-11-14T19:52:00+00:00', 'confirmado'),
  ('r90', 'v17', 'b8', -12.025132, -75.182535, 'asalto_robo', 5, 'Robo al paso a mano armada a transeúnte en Avenida El Sol', '2026-11-20T14:35:00+00:00', 'activo'),
  ('r91', 'v26', 'b8', -12.027243, -75.1918, 'alcohol_drogas', 3, 'Personas bebiendo licor en la acera y bloqueando el paso en Avenida Agricultura', '2026-11-08T09:18:00+00:00', 'confirmado'),
  ('r92', 'v35', 'b8', -12.024585, -75.186515, 'asalto_robo', 5, 'Asalto a una vecina cerca del paradero en Calle 2', '2026-11-14T04:01:00+00:00', 'activo'),
  ('r93', 'v8', 'b8', -12.031215, -75.188639, 'falta_alumbrado', 2, 'Falta total de alumbrado en pasaje peatonal de Jirón Los Álamos', '2026-11-19T23:44:00+00:00', 'confirmado'),
  ('r94', 'v17', 'b8', -12.026656, -75.188721, 'otro', 1, 'Acumulación clandestina de desmonte y basura obstaculizando el tránsito en Calle Cantuta', '2026-11-06T18:27:00+00:00', 'activo'),
  ('r95', 'v26', 'b8', -12.027673, -75.183543, 'pandillaje', 3, 'Enfrentamiento entre grupos callejeros con piedras en JIrón San Felipe', '2026-11-12T13:10:00+00:00', 'confirmado'),
  ('r96', 'v9', 'b9', -12.048414, -75.187325, 'asalto_robo', 5, 'Robo al paso a mano armada a transeúnte en Los Robles', '2026-10-26T13:00:00+00:00', 'activo'),
  ('r97', 'v18', 'b9', -12.048615, -75.194901, 'alcohol_drogas', 3, 'Personas bebiendo licor en la acera y bloqueando el paso en Calle Las Orquideas', '2026-11-14T07:43:00+00:00', 'activo'),
  ('r98', 'v27', 'b9', -12.044275, -75.191176, 'asalto_robo', 5, 'Asalto a una vecina cerca del paradero en Jirón Los Andes', '2026-11-01T02:26:00+00:00', 'activo'),
  ('r99', 'v36', 'b9', -12.050504, -75.191092, 'falta_alumbrado', 2, 'Falta total de alumbrado en pasaje peatonal de Los Fresnos', '2026-10-18T21:09:00+00:00', 'activo'),
  ('r100', 'v9', 'b9', -12.045168, -75.187338, 'otro', 1, 'Acumulación clandestina de desmonte y basura obstaculizando el tránsito en Jirón Jhantu', '2026-11-06T16:52:00+00:00', 'activo'),
  ('r101', 'v18', 'b9', -12.047378, -75.191496, 'pandillaje', 3, 'Enfrentamiento entre grupos callejeros con piedras en Calle El Paraiso', '2026-10-25T11:35:00+00:00', 'activo'),
  ('r102', 'v27', 'b9', -12.047961, -75.189447, 'actividad_sospechosa', 1, 'Desconocidos merodeando de madrugada y observando entradas en Jirón Centauro', '2026-11-13T06:18:00+00:00', 'activo'),
  ('r103', 'v36', 'b9', -12.04977, -75.188761, 'asalto_robo', 5, 'Robo con arma blanca a joven que retornaba a su domicilio en Calle Alameda La Merced Sur', '2026-10-31T01:01:00+00:00', 'activo'),
  ('r104', 'v9', 'b9', -12.045714, -75.190043, 'alcohol_drogas', 3, 'Sujetos consumiendo bebidas alcohólicas y sustancias en la vía pública de Avenida Las Flores', '2026-11-18T20:44:00+00:00', 'activo'),
  ('r105', 'v18', 'b9', -12.047335, -75.1933, 'asalto_robo', 5, 'Arrebato de celular y pertenencias por sujetos en moto en Calle Las Margaritas', '2026-11-05T15:27:00+00:00', 'activo');

-- 5. Insertar votos vecinales de prueba
INSERT INTO public.votos_reporte (id_reporte, id_usuario, voto, fecha) VALUES
  ('r2', 'v2', 'confirmo', '2026-11-09T08:58:00+00:00'),
  ('r2', 'v3', 'confirmo', '2026-11-09T09:58:00+00:00'),
  ('r4', 'v4', 'confirmo', '2026-11-10T22:24:00+00:00'),
  ('r4', 'v5', 'confirmo', '2026-11-10T23:24:00+00:00'),
  ('r6', 'v6', 'confirmo', '2026-11-13T12:50:00+00:00'),
  ('r6', 'v7', 'confirmo', '2026-11-13T13:50:00+00:00'),
  ('r8', 'v8', 'confirmo', '2026-11-15T02:16:00+00:00'),
  ('r8', 'v9', 'confirmo', '2026-11-15T03:16:00+00:00'),
  ('r10', 'v6', 'confirmo', '2026-11-14T11:15:00+00:00'),
  ('r11', 'v6', 'confirmo', '2026-11-01T05:58:00+00:00'),
  ('r11', 'v7', 'confirmo', '2026-11-01T06:58:00+00:00'),
  ('r11', 'v8', 'confirmo', '2026-11-01T07:58:00+00:00'),
  ('r12', 'v7', 'confirmo', '2026-11-12T00:41:00+00:00'),
  ('r13', 'v8', 'confirmo', '2026-10-29T19:24:00+00:00'),
  ('r13', 'v9', 'confirmo', '2026-10-29T20:24:00+00:00'),
  ('r13', 'v10', 'confirmo', '2026-10-29T21:24:00+00:00'),
  ('r14', 'v10', 'confirmo', '2026-11-09T15:07:00+00:00'),
  ('r15', 'v10', 'confirmo', '2026-11-21T09:50:00+00:00'),
  ('r15', 'v12', 'confirmo', '2026-11-21T10:50:00+00:00'),
  ('r15', 'v13', 'confirmo', '2026-11-21T11:50:00+00:00'),
  ('r16', 'v11', 'confirmo', '2026-11-08T04:33:00+00:00'),
  ('r17', 'v12', 'confirmo', '2026-11-18T23:16:00+00:00'),
  ('r17', 'v13', 'confirmo', '2026-11-19T00:16:00+00:00'),
  ('r17', 'v14', 'confirmo', '2026-11-19T01:16:00+00:00'),
  ('r18', 'v14', 'confirmo', '2026-11-05T18:59:00+00:00'),
  ('r19', 'v15', 'confirmo', '2026-11-17T13:42:00+00:00'),
  ('r19', 'v16', 'confirmo', '2026-11-17T14:42:00+00:00'),
  ('r19', 'v17', 'confirmo', '2026-11-17T15:42:00+00:00'),
  ('r20', 'v15', 'confirmo', '2026-11-04T08:25:00+00:00'),
  ('r21', 'v10', 'confirmo', '2026-11-20T08:15:00+00:00'),
  ('r21', 'v11', 'confirmo', '2026-11-20T09:15:00+00:00'),
  ('r21', 'v12', 'confirmo', '2026-11-20T10:15:00+00:00'),
  ('r23', 'v11', 'confirmo', '2026-11-15T21:41:00+00:00'),
  ('r23', 'v12', 'confirmo', '2026-11-15T22:41:00+00:00'),
  ('r24', 'v12', 'confirmo', '2026-11-13T16:24:00+00:00'),
  ('r24', 'v13', 'confirmo', '2026-11-13T17:24:00+00:00'),
  ('r24', 'v14', 'confirmo', '2026-11-13T18:24:00+00:00'),
  ('r25', 'v14', 'confirmo', '2026-11-23T12:07:00+00:00'),
  ('r25', 'v15', 'confirmo', '2026-11-23T13:07:00+00:00'),
  ('r27', 'v15', 'confirmo', '2026-11-19T01:33:00+00:00'),
  ('r27', 'v16', 'confirmo', '2026-11-19T02:33:00+00:00'),
  ('r27', 'v17', 'confirmo', '2026-11-19T03:33:00+00:00'),
  ('r29', 'v18', 'confirmo', '2026-11-14T15:59:00+00:00'),
  ('r29', 'v19', 'confirmo', '2026-11-14T16:59:00+00:00'),
  ('r30', 'v19', 'confirmo', '2026-11-13T10:42:00+00:00'),
  ('r30', 'v20', 'confirmo', '2026-11-13T11:42:00+00:00'),
  ('r30', 'v21', 'confirmo', '2026-11-13T12:42:00+00:00'),
  ('r31', 'v19', 'confirmo', '2026-11-22T05:25:00+00:00'),
  ('r31', 'v20', 'confirmo', '2026-11-22T06:25:00+00:00'),
  ('r33', 'v22', 'confirmo', '2026-11-17T19:51:00+00:00'),
  ('r33', 'v23', 'confirmo', '2026-11-17T20:51:00+00:00'),
  ('r33', 'v24', 'confirmo', '2026-11-17T21:51:00+00:00'),
  ('r35', 'v14', 'confirmo', '2026-11-18T05:15:00+00:00'),
  ('r35', 'v15', 'confirmo', '2026-11-18T06:15:00+00:00'),
  ('r35', 'v16', 'confirmo', '2026-11-18T07:15:00+00:00'),
  ('r36', 'v15', 'confirmo', '2026-11-20T23:58:00+00:00'),
  ('r37', 'v15', 'confirmo', '2026-11-15T18:41:00+00:00'),
  ('r37', 'v16', 'confirmo', '2026-11-15T19:41:00+00:00'),
  ('r37', 'v17', 'confirmo', '2026-11-15T20:41:00+00:00'),
  ('r38', 'v16', 'confirmo', '2026-11-19T13:24:00+00:00'),
  ('r38', 'v17', 'confirmo', '2026-11-19T14:24:00+00:00'),
  ('r38', 'v18', 'confirmo', '2026-11-19T15:24:00+00:00'),
  ('r39', 'v18', 'confirmo', '2026-11-22T09:07:00+00:00'),
  ('r39', 'v19', 'confirmo', '2026-11-22T10:07:00+00:00'),
  ('r39', 'v20', 'confirmo', '2026-11-22T11:07:00+00:00'),
  ('r40', 'v19', 'confirmo', '2026-11-17T03:50:00+00:00'),
  ('r41', 'v19', 'confirmo', '2026-11-19T22:33:00+00:00'),
  ('r41', 'v20', 'confirmo', '2026-11-19T23:33:00+00:00'),
  ('r41', 'v21', 'confirmo', '2026-11-20T00:33:00+00:00'),
  ('r42', 'v20', 'confirmo', '2026-11-22T17:16:00+00:00'),
  ('r43', 'v22', 'confirmo', '2026-11-18T12:59:00+00:00'),
  ('r43', 'v23', 'confirmo', '2026-11-18T13:59:00+00:00'),
  ('r43', 'v24', 'confirmo', '2026-11-18T14:59:00+00:00'),
  ('r44', 'v23', 'confirmo', '2026-11-21T07:42:00+00:00'),
  ('r44', 'v24', 'confirmo', '2026-11-21T08:42:00+00:00'),
  ('r44', 'v25', 'confirmo', '2026-11-21T09:42:00+00:00'),
  ('r45', 'v24', 'confirmo', '2026-11-16T02:25:00+00:00'),
  ('r45', 'v25', 'confirmo', '2026-11-16T03:25:00+00:00'),
  ('r45', 'v26', 'confirmo', '2026-11-16T04:25:00+00:00'),
  ('r46', 'v24', 'confirmo', '2026-11-18T22:08:00+00:00'),
  ('r47', 'v26', 'confirmo', '2026-11-21T16:51:00+00:00'),
  ('r47', 'v27', 'confirmo', '2026-11-21T17:51:00+00:00'),
  ('r47', 'v28', 'confirmo', '2026-11-21T18:51:00+00:00'),
  ('r48', 'v27', 'confirmo', '2026-11-17T11:34:00+00:00'),
  ('r49', 'v28', 'confirmo', '2026-11-20T06:17:00+00:00'),
  ('r49', 'v29', 'confirmo', '2026-11-20T07:17:00+00:00'),
  ('r49', 'v30', 'confirmo', '2026-11-20T08:17:00+00:00'),
  ('r51', 'v19', 'confirmo', '2026-11-16T20:58:00+00:00'),
  ('r51', 'v20', 'confirmo', '2026-11-16T21:58:00+00:00'),
  ('r53', 'v20', 'confirmo', '2026-11-09T10:24:00+00:00'),
  ('r53', 'v21', 'confirmo', '2026-11-09T11:24:00+00:00'),
  ('r55', 'v23', 'confirmo', '2026-11-19T00:50:00+00:00'),
  ('r55', 'v24', 'confirmo', '2026-11-19T01:50:00+00:00'),
  ('r57', 'v24', 'confirmo', '2026-11-10T14:16:00+00:00'),
  ('r57', 'v25', 'confirmo', '2026-11-10T15:16:00+00:00'),
  ('r59', 'v27', 'confirmo', '2026-11-21T04:42:00+00:00'),
  ('r59', 'v28', 'confirmo', '2026-11-21T05:42:00+00:00'),
  ('r61', 'v28', 'confirmo', '2026-11-12T19:08:00+00:00'),
  ('r61', 'v29', 'confirmo', '2026-11-12T20:08:00+00:00'),
  ('r62', 'v22', 'confirmo', '2026-11-12T23:15:00+00:00'),
  ('r63', 'v23', 'confirmo', '2026-10-30T17:58:00+00:00'),
  ('r63', 'v24', 'confirmo', '2026-10-30T18:58:00+00:00'),
  ('r63', 'v25', 'confirmo', '2026-10-30T19:58:00+00:00'),
  ('r64', 'v23', 'confirmo', '2026-11-15T12:41:00+00:00'),
  ('r65', 'v24', 'confirmo', '2026-11-02T07:24:00+00:00'),
  ('r65', 'v25', 'confirmo', '2026-11-02T08:24:00+00:00'),
  ('r65', 'v26', 'confirmo', '2026-11-02T09:24:00+00:00'),
  ('r66', 'v26', 'confirmo', '2026-11-17T03:07:00+00:00'),
  ('r67', 'v27', 'confirmo', '2026-11-03T21:50:00+00:00'),
  ('r67', 'v28', 'confirmo', '2026-11-03T22:50:00+00:00'),
  ('r67', 'v29', 'confirmo', '2026-11-03T23:50:00+00:00'),
  ('r68', 'v28', 'confirmo', '2026-11-18T16:33:00+00:00'),
  ('r69', 'v28', 'confirmo', '2026-11-06T11:16:00+00:00'),
  ('r69', 'v29', 'confirmo', '2026-11-06T12:16:00+00:00'),
  ('r69', 'v30', 'confirmo', '2026-11-06T13:16:00+00:00'),
  ('r70', 'v30', 'confirmo', '2026-10-24T06:59:00+00:00'),
  ('r71', 'v31', 'confirmo', '2026-11-08T01:42:00+00:00'),
  ('r71', 'v32', 'confirmo', '2026-11-08T02:42:00+00:00'),
  ('r71', 'v33', 'confirmo', '2026-11-08T03:42:00+00:00'),
  ('r72', 'v26', 'confirmo', '2026-11-15T20:15:00+00:00'),
  ('r72', 'v27', 'confirmo', '2026-11-15T21:15:00+00:00'),
  ('r74', 'v28', 'confirmo', '2026-11-14T09:41:00+00:00'),
  ('r74', 'v29', 'confirmo', '2026-11-14T10:41:00+00:00'),
  ('r76', 'v30', 'confirmo', '2026-11-12T00:07:00+00:00'),
  ('r76', 'v31', 'confirmo', '2026-11-12T01:07:00+00:00'),
  ('r78', 'v32', 'confirmo', '2026-11-22T13:33:00+00:00'),
  ('r78', 'v33', 'confirmo', '2026-11-22T14:33:00+00:00'),
  ('r80', 'v34', 'confirmo', '2026-11-20T03:59:00+00:00'),
  ('r80', 'v35', 'confirmo', '2026-11-20T04:59:00+00:00'),
  ('r82', 'v36', 'confirmo', '2026-11-17T17:25:00+00:00'),
  ('r82', 'v1', 'confirmo', '2026-11-17T18:25:00+00:00'),
  ('r84', 'v2', 'confirmo', '2026-11-16T07:51:00+00:00'),
  ('r84', 'v3', 'confirmo', '2026-11-16T08:51:00+00:00'),
  ('r85', 'v30', 'confirmo', '2026-11-09T17:15:00+00:00'),
  ('r85', 'v31', 'confirmo', '2026-11-09T18:15:00+00:00'),
  ('r85', 'v32', 'confirmo', '2026-11-09T19:15:00+00:00'),
  ('r86', 'v31', 'confirmo', '2026-11-16T11:58:00+00:00'),
  ('r87', 'v32', 'confirmo', '2026-11-03T06:41:00+00:00'),
  ('r87', 'v33', 'confirmo', '2026-11-03T07:41:00+00:00'),
  ('r87', 'v34', 'confirmo', '2026-11-03T08:41:00+00:00'),
  ('r88', 'v32', 'confirmo', '2026-11-09T01:24:00+00:00'),
  ('r89', 'v34', 'confirmo', '2026-11-14T21:07:00+00:00'),
  ('r89', 'v35', 'confirmo', '2026-11-14T22:07:00+00:00'),
  ('r89', 'v36', 'confirmo', '2026-11-14T23:07:00+00:00'),
  ('r90', 'v35', 'confirmo', '2026-11-20T15:50:00+00:00'),
  ('r91', 'v36', 'confirmo', '2026-11-08T10:33:00+00:00'),
  ('r91', 'v1', 'confirmo', '2026-11-08T11:33:00+00:00'),
  ('r91', 'v2', 'confirmo', '2026-11-08T12:33:00+00:00'),
  ('r92', 'v1', 'confirmo', '2026-11-14T05:16:00+00:00'),
  ('r93', 'v2', 'confirmo', '2026-11-20T00:59:00+00:00'),
  ('r93', 'v3', 'confirmo', '2026-11-20T01:59:00+00:00'),
  ('r93', 'v4', 'confirmo', '2026-11-20T02:59:00+00:00'),
  ('r94', 'v3', 'confirmo', '2026-11-06T19:42:00+00:00'),
  ('r95', 'v4', 'confirmo', '2026-11-12T14:25:00+00:00'),
  ('r95', 'v5', 'confirmo', '2026-11-12T15:25:00+00:00'),
  ('r95', 'v6', 'confirmo', '2026-11-12T16:25:00+00:00'),
  ('r97', 'v35', 'confirmo', '2026-11-14T08:58:00+00:00'),
  ('r97', 'v36', 'confirmo', '2026-11-14T09:58:00+00:00'),
  ('r99', 'v1', 'confirmo', '2026-10-18T22:24:00+00:00'),
  ('r99', 'v2', 'confirmo', '2026-10-18T23:24:00+00:00'),
  ('r101', 'v3', 'confirmo', '2026-10-25T12:50:00+00:00'),
  ('r101', 'v4', 'confirmo', '2026-10-25T13:50:00+00:00'),
  ('r103', 'v5', 'confirmo', '2026-10-31T02:16:00+00:00'),
  ('r103', 'v6', 'confirmo', '2026-10-31T03:16:00+00:00'),
  ('r105', 'v7', 'confirmo', '2026-11-05T16:42:00+00:00'),
  ('r105', 'v8', 'confirmo', '2026-11-05T17:42:00+00:00');

-- 6. Vincular acciones municipales a los reportes más recientes de su barrio
UPDATE public.acciones
SET id_reporte = (
    SELECT id FROM public.reportes
    WHERE id_barrio = 'b1' AND estado <> 'archivado'
    ORDER BY fecha DESC LIMIT 1
)
WHERE id = 'a1';
UPDATE public.acciones
SET id_reporte = (
    SELECT id FROM public.reportes
    WHERE id_barrio = 'b3' AND estado <> 'archivado'
    ORDER BY fecha DESC LIMIT 1
)
WHERE id = 'a4';
UPDATE public.acciones
SET id_reporte = (
    SELECT id FROM public.reportes
    WHERE id_barrio = 'b6' AND estado <> 'archivado'
    ORDER BY fecha DESC LIMIT 1
)
WHERE id = 'a7';
UPDATE public.acciones
SET id_reporte = (
    SELECT id FROM public.reportes
    WHERE id_barrio = 'b5' AND estado <> 'archivado'
    ORDER BY fecha DESC LIMIT 1
)
WHERE id = 'a12';
UPDATE public.acciones
SET id_reporte = (
    SELECT id FROM public.reportes
    WHERE id_barrio = 'b4' AND estado <> 'archivado'
    ORDER BY fecha DESC LIMIT 1
)
WHERE id = 'a16';
UPDATE public.acciones
SET id_reporte = (
    SELECT id FROM public.reportes
    WHERE id_barrio = 'b8' AND estado <> 'archivado'
    ORDER BY fecha DESC LIMIT 1
)
WHERE id = 'a17';

COMMIT;
