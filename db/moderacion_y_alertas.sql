-- =====================================================================
-- Radar Vecinal · Migración de Moderación y Control de Alertas
-- Ejecutar en DBeaver sobre la base de datos PostgreSQL radar_vecinal
-- =====================================================================

BEGIN;

-- 1. Ampliar CHECK de estado en la tabla usuarios para permitir 'Suspendido' y 'Baneado'
ALTER TABLE usuarios DROP CONSTRAINT IF EXISTS usuarios_estado_check;
ALTER TABLE usuarios ADD CONSTRAINT usuarios_estado_check
    CHECK (estado IN ('Pendiente', 'Verificado', 'Rechazado', 'Suspendido', 'Baneado'));

-- 2. Agregar columnas de moderación y strikes en la tabla usuarios
ALTER TABLE usuarios
    ADD COLUMN IF NOT EXISTS strikes SMALLINT NOT NULL DEFAULT 0 CHECK (strikes >= 0),
    ADD COLUMN IF NOT EXISTS suspendido_hasta TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS motivo_sancion TEXT;

-- 3. Agregar columna id_usuario en alertas para trazabilidad del autor
ALTER TABLE alertas
    ADD COLUMN IF NOT EXISTS id_usuario TEXT REFERENCES usuarios(id) ON DELETE SET NULL;

-- 4. Actualizar las vistas dependientes
DROP VIEW IF EXISTS v_alertas_activas CASCADE;
DROP VIEW IF EXISTS v_usuarios CASCADE;

CREATE VIEW v_usuarios AS
SELECT u.id, u.nombre, u.dni, u.correo, u.rol, u.estado,
       u.strikes, u.suspendido_hasta, u.motivo_sancion,
       b.nombre AS barrio, u.institucion, u.fecha_registro
FROM usuarios u
LEFT JOIN barrios b ON b.id = u.id_barrio
ORDER BY u.fecha_registro DESC;

CREATE VIEW v_alertas_activas AS
SELECT a.id, b.nombre AS barrio, a.inicio, a.expira,
       round(extract(epoch FROM (a.expira - now())) / 60.0, 1) AS minutos_restantes,
       a.id_usuario, u.nombre AS autor_nombre, u.dni AS autor_dni
FROM alertas a
JOIN barrios b ON b.id = a.id_barrio
LEFT JOIN usuarios u ON u.id = a.id_usuario
WHERE a.expira > now()
ORDER BY a.expira;

COMMIT;
