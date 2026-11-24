DROP VIEW IF EXISTS v_conteo_tablas, v_resumen_barrios, v_alertas_activas, v_iniciativas, v_acciones, v_reportes, v_usuarios;

CREATE VIEW v_usuarios AS
SELECT u.id, u.nombre, u.dni, u.correo, u.rol, u.estado,
       u.strikes, u.suspendido_hasta, u.motivo_sancion,
       b.nombre AS barrio, u.institucion, u.fecha_registro
FROM usuarios u
LEFT JOIN barrios b ON b.id = u.id_barrio
ORDER BY u.fecha_registro DESC;

CREATE VIEW v_reportes AS
SELECT r.id, r.fecha, b.nombre AS barrio, r.tipo, r.gravedad, r.estado,
       r.descripcion, u.nombre AS autor, r.lat, r.lng,
       (SELECT count(*) FROM votos_reporte v WHERE v.id_reporte = r.id AND v.voto = 'confirmo')   AS confirmaciones,
       (SELECT count(*) FROM votos_reporte v WHERE v.id_reporte = r.id AND v.voto = 'incorrecto') AS incorrectos,
       (SELECT count(*) FROM denuncias_reporte d WHERE d.id_reporte = r.id)                       AS denuncias
FROM reportes r
JOIN barrios  b ON b.id = r.id_barrio
JOIN usuarios u ON u.id = r.id_usuario
ORDER BY r.fecha DESC;

CREATE VIEW v_acciones AS
SELECT a.id, a.fecha, b.nombre AS barrio, a.tipo, a.titulo, a.estado,
       a.institucion, a.id_reporte, cardinality(a.fotos) AS num_fotos,
       a.temperatura_al_completar, a.fecha_registro
FROM acciones a
JOIN barrios b ON b.id = a.id_barrio
ORDER BY a.fecha DESC;

CREATE VIEW v_iniciativas AS
SELECT i.id, b.nombre AS barrio, i.titulo, i.meta, i.estado,
       u.nombre AS creador,
       (SELECT count(*) FROM iniciativa_participantes p WHERE p.id_iniciativa = i.id) AS participantes,
       i.temperatura_al_cumplir, i.fecha_creacion
FROM iniciativas i
JOIN barrios  b ON b.id = i.id_barrio
JOIN usuarios u ON u.id = i.id_creador
ORDER BY i.fecha_creacion DESC;

CREATE VIEW v_alertas_activas AS
SELECT a.id, b.nombre AS barrio, a.inicio, a.expira,
       round(extract(epoch FROM (a.expira - now())) / 60.0, 1) AS minutos_restantes,
       a.id_usuario, u.nombre AS autor_nombre, u.dni AS autor_dni
FROM alertas a
JOIN barrios b ON b.id = a.id_barrio
LEFT JOIN usuarios u ON u.id = a.id_usuario
WHERE a.expira > now()
ORDER BY a.expira;

CREATE VIEW v_resumen_barrios AS
SELECT b.id, b.nombre AS barrio,
       (SELECT count(*) FROM usuarios    u WHERE u.id_barrio = b.id AND u.rol = 'vecino') AS vecinos,
       (SELECT count(*) FROM reportes    r WHERE r.id_barrio = b.id)                      AS reportes,
       (SELECT count(*) FROM reportes    r WHERE r.id_barrio = b.id AND r.estado IN ('activo','confirmado')) AS reportes_vigentes,
       (SELECT count(*) FROM acciones    a WHERE a.id_barrio = b.id)                      AS acciones,
       (SELECT count(*) FROM iniciativas i WHERE i.id_barrio = b.id)                      AS iniciativas
FROM barrios b
ORDER BY length(b.id), b.id;

CREATE VIEW v_conteo_tablas AS
          SELECT 'barrios'                  AS tabla, count(*) AS filas FROM barrios
UNION ALL SELECT 'codigos_barrio',           count(*) FROM codigos_barrio
UNION ALL SELECT 'usuarios',                 count(*) FROM usuarios
UNION ALL SELECT 'reportes',                 count(*) FROM reportes
UNION ALL SELECT 'votos_reporte',            count(*) FROM votos_reporte
UNION ALL SELECT 'denuncias_reporte',        count(*) FROM denuncias_reporte
UNION ALL SELECT 'acciones',                 count(*) FROM acciones
UNION ALL SELECT 'noticias_leidas',          count(*) FROM noticias_leidas
UNION ALL SELECT 'iniciativas',              count(*) FROM iniciativas
UNION ALL SELECT 'iniciativa_participantes', count(*) FROM iniciativa_participantes
UNION ALL SELECT 'alertas',                  count(*) FROM alertas;