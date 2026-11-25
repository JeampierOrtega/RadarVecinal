# Backend – Radar Vecinal

FastAPI + uv + uvicorn. Los datos se guardan en **PostgreSQL** mediante psycopg 3
(pool de conexiones, SQL escrito a mano y parametrizado; sin ORM).

## 1. Base de datos en Docker

La base `radar_vecinal` corre en Docker y escucha en `localhost:5432`.

```bash
docker start <nombre-del-contenedor>
```

Si necesitas crear la base desde cero, ejecuta el esquema (¡elimina y vuelve a crear las
tablas!) y confirma que los 12 barrios quedaron cargados:

```bash
docker exec -i <nombre-del-contenedor> psql -U radar -d radar_vecinal < ../db/schema.sql
```

La aplicación **no** crea barrios ni tablas: asume que `db/schema.sql` ya se ejecutó.

## 2. Variables de entorno

Copia el ejemplo y ajusta los valores de tu contenedor:

```bash
cp .env.example .env
```

| Variable      | Obligatoria | Valor por defecto |
| ------------- | ----------- | ----------------- |
| `DB_HOST`     | Sí          | —                 |
| `DB_NAME`     | Sí          | —                 |
| `DB_USER`     | Sí          | —                 |
| `DB_PASSWORD` | Sí          | —                 |
| `DB_PORT`     | No          | `5432`            |

`.env` está en `.gitignore`; no subas credenciales reales al repositorio.

## 3. Migración de una base existente (Argon2id + secuencias)

El backend nuevo necesita las seis secuencias de IDs y las FKs de `usuarios(id)` con
`ON UPDATE CASCADE`. En una base que ya tiene datos, ejecuta en DBeaver:

```text
db/migrar_argon2_y_secuencias.sql
```

**Antes de arrancar el backend.** Respaldá primero la base (un `pg_dump` completo de
`radar_vecinal`). El script es re-ejecutable, va en una transacción y termina con consultas
de verificación comentadas. El orden correcto es:

1. Respaldar la base.
2. Ejecutar `db/migrar_argon2_y_secuencias.sql` en DBeaver.
3. Ejecutar las consultas de verificación del final del script.
4. Recién entonces `uv run backend`.

En una base nueva, `db/schema.sql` ya crea las secuencias y las 8 FKs con `ON UPDATE
CASCADE`; no hace falta el script de migración.

### Comprobar en DBeaver

```sql
-- IDs de usuario fuera de formato: debe devolver 0 filas
SELECT id, rol FROM usuarios WHERE id !~ '^(v|m)[0-9]+$';

-- Hashes
SELECT count(*) FILTER (WHERE clave_hash LIKE '$argon2id$%') AS argon2id,
       count(*) FILTER (WHERE clave_hash ~ '^[0-9a-f]{64}$')  AS sha256
  FROM usuarios;

-- Secuencias
SELECT sequencename, last_value, is_called
  FROM pg_sequences
 WHERE sequencename LIKE 'seq_%'
 ORDER BY sequencename;
```

Luego iniciá sesión con `vecino@barrio.com` / `123456`; el hash de esa cuenta debe empezar
por `$argon2id$`. Las cuentas con otras claves se migran solas en su próximo login.

## 4. Arranque

```bash
uv sync
uv run pytest        # tests de hash e IDs; no tocan PostgreSQL
uv run backend
```

Al iniciar, el lifespan abre el pool de conexiones y carga los datos de demostración
**solo si las tablas están vacías** (`INSERT ... ON CONFLICT DO NOTHING`). Reiniciar el
backend no borra lo que hayas creado. Después de la carga, el backend ajusta las seis
secuencias con `setval` para que los IDs nuevos no choquen con los fijos de la demo.

Docs interactivas: <http://127.0.0.1:8000/docs>

## 5. Contraseñas e IDs

- `src/backend/core/seguridad.py` centraliza el hashing: Argon2id con los parámetros por
  defecto de `argon2-cffi`. Los SHA-256 heredados se aceptan una vez y se reemplazan por
  Argon2id al iniciar sesión correctamente.
- Los IDs nuevos usan `<prefijo><número>`: `v`, `m`, `r`, `a`, `i` y `al`, generados con
  `nextval` de `seq_usuarios_vecinos`, `seq_usuarios_municipalidad`, `seq_reportes`,
  `seq_acciones`, `seq_iniciativas` y `seq_alertas`. Puede haber huecos.

## Cuentas de demostración

Todas usan la contraseña `123456`:

- Vecino: `vecino@barrio.com`
- Municipalidad: `muni@huancayo.gob.pe`
