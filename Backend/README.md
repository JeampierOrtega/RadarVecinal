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

## 3. Arranque

```bash
uv sync
uv run backend
```

Al iniciar, el lifespan abre el pool de conexiones y carga los datos de demostración
**solo si las tablas están vacías** (`INSERT ... ON CONFLICT DO NOTHING`). Reiniciar el
backend no borra lo que hayas creado.

Docs interactivas: <http://127.0.0.1:8000/docs>

## Cuentas de demostración

Todas usan la contraseña `123456`:

- Vecino: `vecino@barrio.com`
- Municipalidad: `muni@huancayo.gob.pe`
