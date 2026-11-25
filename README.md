# Radar Vecinal

Seguridad ciudadana comunitaria para Huancayo. Dos actores:

- **Vecino**: reporta incidentes, confirma o denuncia reportes, crea y apoya iniciativas.
- **Municipalidad**: revisa reportes, verifica cuentas y responde con acciones.

## Estructura

- `Backend/` — FastAPI + uv + uvicorn, PostgreSQL (psycopg 3, SQL a mano, sin ORM).
- `Frontend/` — Angular 22 con SSR, Bootstrap 5, SweetAlert2 y Leaflet.
- `db/schema.sql` — esquema de PostgreSQL (tablas, claves foráneas y restricciones).

## Base de datos (Docker)

La base `radar_vecinal` corre en Docker en `localhost:5432`. Las credenciales se leen de
`Backend/.env` (copia `Backend/.env.example` y ajusta los valores; `.env` no se versiona).
`DB_PORT` es opcional y vale `5432` si no se define.

## Migración de una base existente (Argon2id + secuencias)

Si la base ya tiene datos, ejecuta **primero** `db/migrar_argon2_y_secuencias.sql` en
DBeaver y recién después arranca el backend. El script:

1. Agrega `ON UPDATE CASCADE` a las 8 claves foráneas que apuntan a `usuarios(id)`.
2. Crea las seis secuencias de IDs.
3. Renombra los IDs de usuario fuera de `^(v|m)[0-9]+$` a `v<n>`/`m<n>`.
4. Ajusta cada secuencia a su máximo actual.
5. Cambia el SHA-256 de `123456` por Argon2id (las demás claves se migran solas en su
   próximo inicio de sesión).

Respaldá la base antes (por ejemplo, un `pg_dump` completo de `radar_vecinal`). El detalle
de riesgos y verificación está al inicio del script. Para una base nueva no hace falta:
`db/schema.sql` ya crea las secuencias y las FKs con `ON UPDATE CASCADE`.

```powershell
cd "Radar Vecinal\Backend"
uv sync
uv run pytest                     # tests sin tocar PostgreSQL
uv run backend                    # API en http://127.0.0.1:8000/docs

cd "Radar Vecinal\Frontend"
npm install
npm start                         # app en http://localhost:4200
```

Los datos de demostración se cargan solos al arrancar el backend **si las tablas están
vacías**, así que reiniciar no borra los cambios.

## Contraseñas e IDs

- Las claves se guardan con **Argon2id**. El backend acepta los SHA-256 heredados y los
  reemplaza por Argon2id en el primer inicio de sesión correcto.
- Los IDs nuevos son `<prefijo><número>`: `v` (vecinos), `m` (municipalidad), `r`
  (reportes), `a` (acciones), `i` (iniciativas) y `al` (alertas), generados por secuencias
  de PostgreSQL (`seq_*`). Puede haber huecos; es normal.

### Comprobar la migración

En DBeaver, después del `COMMIT`:

```sql
SELECT id, rol FROM usuarios WHERE id !~ '^(v|m)[0-9]+$';             -- 0 filas
SELECT count(*) FILTER (WHERE clave_hash LIKE '$argon2id$%') AS argon2id,
       count(*) FILTER (WHERE clave_hash ~ '^[0-9a-f]{64}$')  AS sha256
  FROM usuarios;
SELECT sequencename, last_value, is_called
  FROM pg_sequences
 WHERE sequencename LIKE 'seq_%'
 ORDER BY sequencename;
```

Después, iniciá sesión con `vecino@barrio.com` / `123456` y verifica con
`SELECT clave_hash FROM usuarios WHERE correo = 'vecino@barrio.com';` que empieza por
`$argon2id$`.

## Cuentas de demostración

Contraseña para todas: `123456`.

- Vecino: `vecino@barrio.com`
- Municipalidad: `muni@huancayo.gob.pe`

Más detalles del backend en `Backend/README.md`.
