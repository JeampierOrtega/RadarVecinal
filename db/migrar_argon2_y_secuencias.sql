-- =====================================================================
-- Radar Vecinal · Migración: contraseñas Argon2id + IDs con secuencias
-- =====================================================================
-- Ejecutar en DBeaver sobre la base `radar_vecinal` UNA VEZ.
-- El script es re-ejecutable: las secuencias usan IF NOT EXISTS, las FKs solo se
-- recrean si aún no tienen ON UPDATE CASCADE, el renombrado ignora los IDs que ya
-- cumplen el formato y el hash solo se actualiza si coincide con el SHA-256 exacto.
--
-- IMPORTANTE: ejecuta este script ANTES de arrancar el backend con el código nuevo.
-- El backend nuevo espera que existan las 6 secuencias.
--
-- Respaldar antes (ver README): pg_dump completo de radar_vecinal, en especial
-- usuarios, reportes, votos_reporte, denuncias_reporte, acciones, noticias_leidas,
-- iniciativas, iniciativa_participantes y alertas (además del esquema y secuencias).
-- =====================================================================


-- ---------------------------------------------------------------------
-- DIAGNÓSTICO PREVIO (descomentar y ejecutar aparte si se desea)
-- ---------------------------------------------------------------------
-- Usuarios con ID fuera del formato ^(v|m)[0-9]+$ (se normalizan más abajo):
-- SELECT id, rol, fecha_registro
--   FROM usuarios
--  WHERE id !~ '^(v|m)[0-9]+$'
--  ORDER BY rol, fecha_registro, id;
--
-- Reparto de hashes actuales:
-- SELECT count(*) FILTER (WHERE clave_hash LIKE '$argon2%')          AS argon2,
--        count(*) FILTER (WHERE clave_hash ~ '^[0-9a-f]{64}$')       AS sha256_hex,
--        count(*) FILTER (WHERE clave_hash !~ '^[0-9a-f]{64}$'
--                           AND clave_hash NOT LIKE '$argon2%')      AS otro_formato
--   FROM usuarios;
--
-- Cuántos usuarios tienen exactamente el SHA-256 de "123456":
-- SELECT count(*) FROM usuarios
--  WHERE clave_hash = '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92';


BEGIN;

-- ---------------------------------------------------------------------
-- 1) Recrear las 8 FKs hacia usuarios(id) con ON UPDATE CASCADE,
--    conservando el ON DELETE actual de cada una.
-- ---------------------------------------------------------------------
DO $$
DECLARE
  f record;
  del text;
BEGIN
  FOR f IN
    SELECT con.conrelid::regclass AS tabla,
           con.conname,
           con.confdeltype,
           (SELECT a.attname
              FROM pg_attribute a
             WHERE a.attrelid = con.conrelid
               AND a.attnum = con.conkey[1]) AS col
      FROM pg_constraint con
     WHERE con.contype = 'f'
       AND con.confrelid = 'usuarios'::regclass
       AND con.confupdtype <> 'c'
  LOOP
    del := CASE f.confdeltype
             WHEN 'c' THEN 'CASCADE'
             WHEN 'n' THEN 'SET NULL'
             WHEN 'r' THEN 'RESTRICT'
             WHEN 'd' THEN 'SET DEFAULT'
             ELSE 'NO ACTION'
           END;
    EXECUTE format('ALTER TABLE %s DROP CONSTRAINT %I', f.tabla, f.conname);
    EXECUTE format(
      'ALTER TABLE %s ADD CONSTRAINT %I FOREIGN KEY (%I) REFERENCES usuarios(id) ON UPDATE CASCADE ON DELETE %s',
      f.tabla, f.conname, f.col, del
    );
  END LOOP;
END $$;

-- ---------------------------------------------------------------------
-- 2) Secuencias de IDs: <prefijo><número>
-- ---------------------------------------------------------------------
CREATE SEQUENCE IF NOT EXISTS seq_usuarios_vecinos;
CREATE SEQUENCE IF NOT EXISTS seq_usuarios_municipalidad;
CREATE SEQUENCE IF NOT EXISTS seq_reportes;
CREATE SEQUENCE IF NOT EXISTS seq_acciones;
CREATE SEQUENCE IF NOT EXISTS seq_iniciativas;
CREATE SEQUENCE IF NOT EXISTS seq_alertas;

-- ---------------------------------------------------------------------
-- 3) Normalizar SOLO los IDs de usuarios que no cumplen ^v[0-9]+$ / ^m[0-9]+$.
--    Los IDs de reportes, acciones, iniciativas y alertas NO se renombran.
--    El UPDATE de la PK se propaga a las 8 FKs gracias al ON UPDATE CASCADE.
-- ---------------------------------------------------------------------
DO $$
DECLARE
  r record;
  maxn int;
BEGIN
  -- Vecinos: v_xxxxxxxx -> v41, v42, ...
  SELECT coalesce(max(substring(id from 2)::int), 0) INTO maxn
    FROM usuarios
   WHERE id ~ '^v[0-9]+$';

  FOR r IN
    SELECT id
      FROM usuarios
     WHERE rol = 'vecino'
       AND id !~ '^v[0-9]+$'
     ORDER BY fecha_registro, id
  LOOP
    maxn := maxn + 1;
    UPDATE usuarios SET id = 'v' || maxn WHERE id = r.id;
  END LOOP;

  -- Municipalidad: cualquier ID fuera de formato -> m<n>.
  SELECT coalesce(max(substring(id from 2)::int), 0) INTO maxn
    FROM usuarios
   WHERE id ~ '^m[0-9]+$';

  FOR r IN
    SELECT id
      FROM usuarios
     WHERE rol = 'municipalidad'
       AND id !~ '^m[0-9]+$'
     ORDER BY fecha_registro, id
  LOOP
    maxn := maxn + 1;
    UPDATE usuarios SET id = 'm' || maxn WHERE id = r.id;
  END LOOP;
END $$;

-- ---------------------------------------------------------------------
-- 4) Ajustar cada secuencia al máximo ID numérico existente (mínimo 1).
--    Con is_called = true, el próximo nextval devuelve max + 1.
--    Nota: si la tabla está vacía, la secuencia queda en 1 y el primer ID es 2.
-- ---------------------------------------------------------------------
SELECT setval(
  'seq_usuarios_vecinos',
  greatest(coalesce((SELECT max(substring(id from 2)::int) FROM usuarios WHERE id ~ '^v[0-9]+$'), 0), 1),
  true
);

SELECT setval(
  'seq_usuarios_municipalidad',
  greatest(coalesce((SELECT max(substring(id from 2)::int) FROM usuarios WHERE id ~ '^m[0-9]+$'), 0), 1),
  true
);

SELECT setval(
  'seq_reportes',
  greatest(coalesce((SELECT max(substring(id from 2)::int) FROM reportes WHERE id ~ '^r[0-9]+$'), 0), 1),
  true
);

SELECT setval(
  'seq_acciones',
  greatest(coalesce((SELECT max(substring(id from 2)::int) FROM acciones WHERE id ~ '^a[0-9]+$'), 0), 1),
  true
);

SELECT setval(
  'seq_iniciativas',
  greatest(coalesce((SELECT max(substring(id from 2)::int) FROM iniciativas WHERE id ~ '^i[0-9]+$'), 0), 1),
  true
);

SELECT setval(
  'seq_alertas',
  greatest(coalesce((SELECT max(substring(id from 3)::int) FROM alertas WHERE id ~ '^al[0-9]+$'), 0), 1),
  true
);

-- ---------------------------------------------------------------------
-- 5) Migrar únicamente el SHA-256 exacto de "123456" al hash Argon2id real.
--    Hash generado con argon2-cffi 25.1.0 y verificado con PasswordHasher.verify().
--    Las demás cuentas conservan su hash y se migran solas en su próximo inicio
--    de sesión: el backend compara el SHA-256 en tiempo constante y, si la clave
--    es correcta, guarda Argon2id en la misma operación. Las claves reales no se
--    sobrescriben porque el script solo toca este valor literal.
-- ---------------------------------------------------------------------
UPDATE usuarios
   SET clave_hash = '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY'
 WHERE clave_hash = '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92';

COMMIT;


-- =====================================================================
-- VERIFICACIÓN (descomentar y ejecutar después del COMMIT)
-- =====================================================================

-- 1. IDs de usuarios fuera de formato: debe devolver 0 filas.
-- SELECT id, rol FROM usuarios WHERE id !~ '^(v|m)[0-9]+$';
--
-- 2. Hashes: $argon2id$ vs SHA-256 restante.
-- SELECT count(*) FILTER (WHERE clave_hash LIKE '$argon2id$%') AS argon2id,
--        count(*) FILTER (WHERE clave_hash ~ '^[0-9a-f]{64}$') AS sha256_hex,
--        count(*) FILTER (WHERE clave_hash LIKE '$argon2%'
--                           AND clave_hash NOT LIKE '$argon2id$%') AS argon2_otro
--   FROM usuarios;
--
-- 3. Valor actual de cada secuencia (last_value + is_called).
-- SELECT sequencename, last_value, is_called
--   FROM pg_sequences
--  WHERE schemaname = current_schema()
--    AND sequencename IN ('seq_usuarios_vecinos', 'seq_usuarios_municipalidad',
--                         'seq_reportes', 'seq_acciones', 'seq_iniciativas',
--                         'seq_alertas')
--  ORDER BY sequencename;
--
-- 4. Las 8 FKs hacia usuarios(id), con su ON UPDATE y ON DELETE.
-- SELECT con.conrelid::regclass AS tabla,
--        con.conname             AS restriccion,
--        con.confupdtype         AS on_update,  -- c = CASCADE
--        con.confdeltype         AS on_delete   -- c = CASCADE, n = SET NULL, r = RESTRICT
--   FROM pg_constraint con
--  WHERE con.contype = 'f'
--    AND con.confrelid = 'usuarios'::regclass
--  ORDER BY tabla, restriccion;
