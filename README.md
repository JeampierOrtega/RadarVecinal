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

## Arranque

```powershell
cd "Radar Vecinal\Backend"
uv sync
uv run backend                    # API en http://127.0.0.1:8000/docs

cd "Radar Vecinal\Frontend"
npm install
npm start                         # app en http://localhost:4200
```

Los datos de demostración se cargan solos al arrancar el backend **si las tablas están
vacías**, así que reiniciar no borra los cambios.

## Cuentas de demostración

Contraseña para todas: `123456`.

- Vecino: `vecino@barrio.com`
- Municipalidad: `muni@huancayo.gob.pe`

Más detalles del backend en `Backend/README.md`.
