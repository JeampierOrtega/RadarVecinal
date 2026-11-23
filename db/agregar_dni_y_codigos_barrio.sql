-- =====================================================================
-- Radar Vecinal · Validación de identidad por DNI y Códigos de Acceso por Barrio
-- Ejecutar en DBeaver sobre la base de datos `radar_vecinal`
-- =====================================================================

BEGIN;

-- 1. Agregar columna dni a la tabla usuarios (si aún no existe)
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS dni CHAR(8);

-- 2. Asignar DNIs ficticios únicos de 8 dígitos a las cuentas demo existentes
UPDATE usuarios SET dni = '40000001' WHERE id = 'v1';
UPDATE usuarios SET dni = '40000002' WHERE id = 'v2';
UPDATE usuarios SET dni = '40000003' WHERE id = 'v3';
UPDATE usuarios SET dni = '40000004' WHERE id = 'v4';
UPDATE usuarios SET dni = '40000005' WHERE id = 'v5';
UPDATE usuarios SET dni = '40000006' WHERE id = 'v6';
UPDATE usuarios SET dni = '40000007' WHERE id = 'v7';
UPDATE usuarios SET dni = '40000008' WHERE id = 'v8';
UPDATE usuarios SET dni = '40000009' WHERE id = 'v9';
UPDATE usuarios SET dni = '40000010' WHERE id = 'v10';
UPDATE usuarios SET dni = '40000011' WHERE id = 'v11';
UPDATE usuarios SET dni = '40000012' WHERE id = 'v12';
UPDATE usuarios SET dni = '40000013' WHERE id = 'v13';
UPDATE usuarios SET dni = '40000014' WHERE id = 'v14';
UPDATE usuarios SET dni = '40000015' WHERE id = 'v15';
UPDATE usuarios SET dni = '40000016' WHERE id = 'v16';
UPDATE usuarios SET dni = '40000017' WHERE id = 'v17';
UPDATE usuarios SET dni = '40000018' WHERE id = 'v18';
UPDATE usuarios SET dni = '40000019' WHERE id = 'v19';
UPDATE usuarios SET dni = '40000020' WHERE id = 'v20';
UPDATE usuarios SET dni = '40000021' WHERE id = 'v21';
UPDATE usuarios SET dni = '40000022' WHERE id = 'v22';
UPDATE usuarios SET dni = '40000023' WHERE id = 'v23';
UPDATE usuarios SET dni = '40000024' WHERE id = 'v24';
UPDATE usuarios SET dni = '40000025' WHERE id = 'v25';
UPDATE usuarios SET dni = '40000026' WHERE id = 'v26';
UPDATE usuarios SET dni = '40000027' WHERE id = 'v27';
UPDATE usuarios SET dni = '40000028' WHERE id = 'v28';
UPDATE usuarios SET dni = '40000029' WHERE id = 'v29';
UPDATE usuarios SET dni = '40000030' WHERE id = 'v30';
UPDATE usuarios SET dni = '40000031' WHERE id = 'v31';
UPDATE usuarios SET dni = '40000032' WHERE id = 'v32';
UPDATE usuarios SET dni = '40000033' WHERE id = 'v33';
UPDATE usuarios SET dni = '40000034' WHERE id = 'v34';
UPDATE usuarios SET dni = '40000035' WHERE id = 'v35';
UPDATE usuarios SET dni = '40000036' WHERE id = 'v36';
UPDATE usuarios SET dni = '40000037' WHERE id = 'v37';
UPDATE usuarios SET dni = '40000038' WHERE id = 'v38';
UPDATE usuarios SET dni = '40000039' WHERE id = 'v39';
UPDATE usuarios SET dni = '40000040' WHERE id = 'v40';
UPDATE usuarios SET dni = '00000001' WHERE id = 'm1';

-- Asignar DNI correlativo único a cualquier usuario adicional que tenga dni nulo
WITH usuarios_sin_dni AS (
    SELECT id, ROW_NUMBER() OVER (ORDER BY fecha_registro, id) AS rn
    FROM usuarios
    WHERE dni IS NULL
)
UPDATE usuarios u
SET dni = LPAD((50000000 + usd.rn)::TEXT, 8, '0')
FROM usuarios_sin_dni usd
WHERE u.id = usd.id;

-- 3. Establecer NOT NULL y restricciones en usuarios(dni)
ALTER TABLE usuarios ALTER COLUMN dni SET NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_usuarios_dni_formato'
    ) THEN
        ALTER TABLE usuarios
            ADD CONSTRAINT chk_usuarios_dni_formato CHECK (dni ~ '^[0-9]{8}$');
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_usuarios_dni'
    ) THEN
        ALTER TABLE usuarios
            ADD CONSTRAINT uq_usuarios_dni UNIQUE (dni);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_usuarios_dni ON usuarios(dni);

-- 4. Actualizar la vista v_usuarios para incluir el DNI
CREATE OR REPLACE VIEW v_usuarios AS
SELECT u.id, u.nombre, u.dni, u.correo, u.rol, u.estado,
       b.nombre AS barrio, u.institucion, u.fecha_registro
FROM usuarios u
LEFT JOIN barrios b ON b.id = u.id_barrio
ORDER BY u.fecha_registro DESC;

-- 5. Crear tabla codigos_barrio
CREATE TABLE IF NOT EXISTS codigos_barrio (
    id                TEXT PRIMARY KEY,
    id_barrio         TEXT NOT NULL REFERENCES barrios(id) ON UPDATE CASCADE ON DELETE CASCADE,
    codigo            TEXT NOT NULL UNIQUE,
    activo            BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_expiracion  TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_codigos_barrio_barrio ON codigos_barrio(id_barrio);
CREATE INDEX IF NOT EXISTS idx_codigos_barrio_codigo ON codigos_barrio(codigo);

-- 6. Insertar los 9 códigos iniciales activos para los barrios b1 a b9
INSERT INTO codigos_barrio (id, id_barrio, codigo, activo, fecha_expiracion)
VALUES
    ('c_b1', 'b1', 'TORRE-2026',       TRUE, NULL),
    ('c_b2', 'b2', 'PALIAN-2026',      TRUE, NULL),
    ('c_b3', 'b3', 'SANCARLOS-2026',   TRUE, NULL),
    ('c_b4', 'b4', 'MONUMENTAL-2026',  TRUE, NULL),
    ('c_b5', 'b5', 'OCOPILLA-2026',    TRUE, NULL),
    ('c_b6', 'b6', 'CAJASCHICO-2026',  TRUE, NULL),
    ('c_b7', 'b7', 'SANANTONIO-2026',  TRUE, NULL),
    ('c_b8', 'b8', 'UNAS-2026',        TRUE, NULL),
    ('c_b9', 'b9', 'CHORRILLOS-2026',  TRUE, NULL)
ON CONFLICT (id) DO UPDATE SET
    id_barrio = EXCLUDED.id_barrio,
    codigo = EXCLUDED.codigo,
    activo = EXCLUDED.activo,
    fecha_expiracion = EXCLUDED.fecha_expiracion;

COMMIT;
