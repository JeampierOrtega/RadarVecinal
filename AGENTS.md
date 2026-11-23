# AGENTS.md

## Repo shape
- Everything lives under `Radar Vecinal/` (space in the path; quote it). Two independent apps, no root manifest or task runner:
  - `Backend/` — FastAPI, Python >= 3.13, uv, PostgreSQL (psycopg 3, SQL a mano, sin ORM).
  - `Frontend/` — Angular 22 with SSR, Bootstrap 5, SweetAlert2, Leaflet.
- This workspace is not a Git repo and has no CI. The only frontend test is `Frontend/src/app/app.spec.ts`; the backend has no tests.

## Commands
```powershell
cd "Radar Vecinal\Backend"
uv sync
uv run backend                                  # 127.0.0.1:8000 with reload

cd "Radar Vecinal\Frontend"
npm install
npm start                                       # localhost:4200, SSR dev server
npm run build                                   # production + SSR build
npm test                                        # Vitest
npx ng test --include src/app/app.spec.ts       # one test file
```
- Backend entrypoint is `uv run backend` -> `Backend/src/backend/__init__.py`; app wiring is in `Backend/src/backend/main.py`. Swagger: `/docs`.
- PostgreSQL runs in Docker at `localhost:5432` (`radar_vecinal`). The credentials come from `Backend/.env` (copy `Backend/.env.example`); `.env` is gitignored. `DB_PORT` is optional and defaults to 5432. The schema lives in `db/schema.sql` and the 12 barrios are already loaded.
- Frontend has no dev proxy. The API base URL comes from `Frontend/src/environments/environment.development.ts` in development and `environment.ts` in production (replacement configured in `angular.json`). `ApiService` reads `environment.apiUrl`.
- Frontend formatting follows `Frontend/.prettierrc` (100 cols, single quotes, Angular HTML parser).

## Backend conventions
- Layers: `apis/` (routers) -> `services/` (rules; raise domain exceptions) -> `repositories/` (SQL a mano con psycopg) with `schemas/` (Pydantic). Routers must be explicitly registered in `main.py`; adding a router file is not enough.
- Raise exceptions from `services/exceptions.py`, not FastAPI `HTTPException`; `main.py` maps them to the uniform `{"status": <code>, "detail": "..."}` response.
- `src/backend/db.py` owns the `psycopg_pool.ConnectionPool` (rows as dicts via `row_factory=dict_row`). `main.py` opens it in the lifespan, runs the seed, and closes it on shutdown. Importing the app must not connect; the pool starts closed.
- All queries are parameterized with `%s`; never interpolate user data. Repositories return the same Pydantic models as before, so `apis/` and most of `services/` stay untouched. Multi-step operations (votar + recalcular confirmaciones, sumarse + contar participantes) go through one repository method and one transaction.
- Data persists in PostgreSQL. `services/datos_iniciales.py` is idempotent: it only fills tables that are empty and uses `INSERT ... ON CONFLICT DO NOTHING`, so restarting the backend does not reset changes. Demo password is `123456`; accounts are in the root README.
- `confirmaciones` and `denuncias` are not columns of `reportes`: they are counted from `votos_reporte` and `denuncias_reporte`. `iniciativas.participantes` is `COUNT(*)` of `iniciativa_participantes`. Barrio polygons are JSONB converted to `list[tuple[float, float]]`; `acciones.fotos` is `TEXT[]`.
- Auth is not JWT: login returns a `Usuario`, then the frontend sends `X-Usuario-Id`. `apis/dependencias.py` enforces session, verification, and role (`VecinoDep`, `MunicipalidadDep`, etc.). Test with curl using `-H "X-Usuario-Id: v1"`.
- Declare static routes before `/{id}` routes (see the `/reportes/mios` comment), otherwise FastAPI treats the name as an ID.
- JSON and Pydantic fields use `snake_case`.

## Temperatura de un barrio
`services/temperatura.py` calcula el nivel que colorea el mapa (`verde` < 8 <= `amarillo` < 18 <= `naranja` <= 30 < `rojo`) y es la misma escala que usan `temperatura_al_completar` y `temperatura_al_cumplir`:

- Peso de cada reporte: `gravedad × (1 + 0.5 × min(confirmaciones, 3)/3) × 0.5^(días/15)`, con vida media de 15 días.
- Bono de novedad **por barrio**, no por reporte: cada reporte nuevo con `estado` distinto de `falso`/`archivado` suma `2 × max(0, 1 − días/7)`; el bono total del barrio se corta en `+6` (`BONO_NOVEDAD_TOPE`).
- Un solo asalto (gravedad 5) en un barrio sin actividad da `5 + 2 = 7.0` → **verde**. Hacen falta al menos **dos** reportes graves recientes para llegar a `amarillo`, y tres para `naranja`. No bajes el umbral de 8 esperando que un reporte cambie el color.
- Los tests de esta regla están en `Backend/tests/test_temperatura.py` (pytest, sin DB).

## Frontend conventions
- Keep Spanish naming for files, classes, methods, and UI text. `Interfaces/` types intentionally mirror backend `snake_case` fields.
- All HTTP goes through `Services/api.service.ts` (`get/post/put/patch/delete`), which prepends `environment.apiUrl`, applies a 20-second timeout, returns Promises, and throws `ApiError` with the HTTP status. Put endpoint calls in feature services (`reportes`, `acciones`, etc.), not in components.
- Initial data loads use the shared `Cargando` and `ErrorCarga` components (`Components/cargando`, `Components/error-carga`) with an inline retry action. Do not leave a failed load showing an empty state or a permanent "Cargando…".
- Do not bypass session handling: `sesion.interceptor.ts` adds `X-Usuario-Id`, `AuthService` persists the session in `sessionStorage` and tracks `sesionExpirada`, and route guards live in `auth.guard.ts`.
- Forms use Signal Forms (`form()`, `[formField]`, `submit()` from `@angular/forms/signals`), not Reactive Forms or `ngModel`.
- User-facing alerts go through `NotificacionesService` (SweetAlert2), which formats `ApiError` status/details.
- Components are standalone and lazy-loaded in `app.routes.ts`; add screens there with the correct role guard. SSR is enabled, so guard browser-only APIs (`sessionStorage`, `window`, Leaflet).
- `mapa-calor.ts` usa panes propios (`barrios` 350 < `calor` 380 < `alertas` 410 < `puntos` 640, por debajo de `tooltipPane`) y un `L.svg({ pane })` por pane: con `preferCanvas` todos los vectores comparten un canvas y el z-index no basta. Los SVG de barrios/alertas/puntos y el canvas de calor llevan `pointer-events: none` para que solo capture el ratón el trazo dibujado. El temporizador de cada segundo solo debe redibujar la capa de alertas; los tooltips de los puntos se arman con DOM + `textContent` (la descripción la escribe el vecino).

## Frontend-backend gotcha
- CORS is configured in `Backend/src/backend/main.py` for `http://localhost:4200` and `http://127.0.0.1:4200`, with `X-Usuario-Id` allowed. If you add a new custom request header, update `allow_headers` or browser calls will fail preflight.
- `ng serve` uses `environment.development.ts`; `ng build` uses `environment.ts`. Change both when the backend URL changes.
