-- =====================================================================
-- Radar Vecinal · Esquema PostgreSQL (sin ORM)
-- =====================================================================

DROP TABLE IF EXISTS alertas                  CASCADE;
DROP TABLE IF EXISTS iniciativa_participantes CASCADE;
DROP TABLE IF EXISTS iniciativas              CASCADE;
DROP TABLE IF EXISTS noticias_leidas          CASCADE;
DROP TABLE IF EXISTS acciones                 CASCADE;
DROP TABLE IF EXISTS denuncias_reporte        CASCADE;
DROP TABLE IF EXISTS votos_reporte            CASCADE;
DROP TABLE IF EXISTS reportes                 CASCADE;
DROP TABLE IF EXISTS usuarios                 CASCADE;
DROP TABLE IF EXISTS codigos_barrio           CASCADE;
DROP TABLE IF EXISTS barrios                  CASCADE;

-- ---------- SECUENCIAS DE IDs ----------
-- Los IDs nuevos usan el formato <prefijo><número>. Las secuencias son independientes
-- de las tablas para conservar el id como llave primaria subrogada.
CREATE SEQUENCE IF NOT EXISTS seq_usuarios_vecinos;
CREATE SEQUENCE IF NOT EXISTS seq_usuarios_municipalidad;
CREATE SEQUENCE IF NOT EXISTS seq_reportes;
CREATE SEQUENCE IF NOT EXISTS seq_acciones;
CREATE SEQUENCE IF NOT EXISTS seq_iniciativas;
CREATE SEQUENCE IF NOT EXISTS seq_alertas;

-- ---------- BARRIOS ----------
CREATE TABLE barrios (
    id        TEXT PRIMARY KEY,
    nombre    TEXT  NOT NULL UNIQUE,
    poligono  JSONB NOT NULL
        CHECK (jsonb_typeof(poligono) = 'array')
);

-- ---------- CÓDIGOS DE ACCESO POR BARRIO ----------
CREATE TABLE codigos_barrio (
    id                TEXT PRIMARY KEY,
    id_barrio         TEXT NOT NULL REFERENCES barrios(id) ON UPDATE CASCADE ON DELETE CASCADE,
    codigo            TEXT NOT NULL UNIQUE,
    activo            BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_expiracion  TIMESTAMPTZ
);
CREATE INDEX idx_codigos_barrio_barrio ON codigos_barrio(id_barrio);
CREATE INDEX idx_codigos_barrio_codigo ON codigos_barrio(codigo);

-- ---------- USUARIOS ----------
CREATE TABLE usuarios (
    id              TEXT PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL CHECK (char_length(nombre) >= 3),
    dni             CHAR(8)      NOT NULL UNIQUE
        CHECK (dni ~ '^[0-9]{8}$'),
    correo          TEXT         NOT NULL UNIQUE
        CHECK (correo ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
    clave_hash      TEXT         NOT NULL,
    rol             TEXT         NOT NULL CHECK (rol IN ('vecino', 'municipalidad')),
    id_barrio       TEXT REFERENCES barrios(id) ON UPDATE CASCADE ON DELETE SET NULL,
    estado          TEXT         NOT NULL DEFAULT 'Pendiente'
        CHECK (estado IN ('Pendiente', 'Verificado', 'Rechazado', 'Suspendido', 'Baneado')),
    strikes         SMALLINT     NOT NULL DEFAULT 0 CHECK (strikes >= 0),
    suspendido_hasta TIMESTAMPTZ,
    motivo_sancion  TEXT,
    fecha_registro  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    institucion     TEXT
);
CREATE INDEX idx_usuarios_barrio ON usuarios(id_barrio);
CREATE INDEX idx_usuarios_estado ON usuarios(estado);
CREATE INDEX idx_usuarios_dni    ON usuarios(dni);

-- ---------- REPORTES ----------
CREATE TABLE reportes (
    id           TEXT PRIMARY KEY,
    id_usuario   TEXT NOT NULL REFERENCES usuarios(id) ON UPDATE CASCADE ON DELETE CASCADE,
    id_barrio    TEXT NOT NULL REFERENCES barrios(id)  ON UPDATE CASCADE,
    lat          DOUBLE PRECISION NOT NULL CHECK (lat BETWEEN -90  AND 90),
    lng          DOUBLE PRECISION NOT NULL CHECK (lng BETWEEN -180 AND 180),
    tipo         TEXT NOT NULL CHECK (tipo IN (
                    'asalto_robo', 'pandillaje', 'alcohol_drogas',
                    'falta_alumbrado', 'actividad_sospechosa', 'otro')),
    gravedad     SMALLINT NOT NULL CHECK (gravedad >= 0),
    descripcion  VARCHAR(280) NOT NULL CHECK (char_length(btrim(descripcion)) >= 1),
    fecha        TIMESTAMPTZ NOT NULL DEFAULT now(),
    estado       TEXT NOT NULL DEFAULT 'activo'
        CHECK (estado IN ('activo', 'confirmado', 'falso', 'archivado'))
);
CREATE INDEX idx_reportes_barrio  ON reportes(id_barrio);
CREATE INDEX idx_reportes_usuario ON reportes(id_usuario);
CREATE INDEX idx_reportes_estado  ON reportes(estado);
CREATE INDEX idx_reportes_fecha   ON reportes(fecha DESC);

-- Votos de vecinos sobre un reporte (1 voto por vecino y reporte)
CREATE TABLE votos_reporte (
    id_reporte  TEXT NOT NULL REFERENCES reportes(id) ON DELETE CASCADE,
    id_usuario  TEXT NOT NULL REFERENCES usuarios(id) ON UPDATE CASCADE ON DELETE CASCADE,
    voto        TEXT NOT NULL CHECK (voto IN ('confirmo', 'incorrecto')),
    fecha       TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id_reporte, id_usuario)
);

-- Denuncias para revisión (1 por vecino y reporte)
CREATE TABLE denuncias_reporte (
    id_reporte  TEXT NOT NULL REFERENCES reportes(id) ON DELETE CASCADE,
    id_usuario  TEXT NOT NULL REFERENCES usuarios(id) ON UPDATE CASCADE ON DELETE CASCADE,
    fecha       TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id_reporte, id_usuario)
);

-- ---------- ACCIONES MUNICIPALES ----------
CREATE TABLE acciones (
    id                        TEXT PRIMARY KEY,
    id_barrio                 TEXT NOT NULL REFERENCES barrios(id)  ON UPDATE CASCADE,
    id_autoridad              TEXT NOT NULL REFERENCES usuarios(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    institucion               TEXT NOT NULL,
    tipo                      TEXT NOT NULL CHECK (tipo IN (
                                 'Patrullaje de serenazgo', 'Operativo con la policía',
                                 'Alumbrado', 'Campaña de prevención', 'Otro')),
    titulo                    VARCHAR(100) NOT NULL CHECK (char_length(btrim(titulo)) >= 1),
    descripcion               VARCHAR(400) NOT NULL CHECK (char_length(btrim(descripcion)) >= 1),
    fecha                     TIMESTAMPTZ  NOT NULL,
    estado                    TEXT NOT NULL CHECK (estado IN ('Planificada', 'En ejecución', 'Completada')),
    fotos                     TEXT[] NOT NULL DEFAULT '{}'
        CHECK (cardinality(fotos) <= 4),
    id_reporte                TEXT REFERENCES reportes(id) ON DELETE SET NULL,
    fecha_registro            TIMESTAMPTZ NOT NULL DEFAULT now(),
    temperatura_al_completar  DOUBLE PRECISION
);
CREATE INDEX idx_acciones_barrio  ON acciones(id_barrio);
CREATE INDEX idx_acciones_reporte ON acciones(id_reporte);
CREATE INDEX idx_acciones_estado  ON acciones(estado);

-- Noticias (acciones) ya leídas por cada vecino
CREATE TABLE noticias_leidas (
    id_usuario  TEXT NOT NULL REFERENCES usuarios(id) ON UPDATE CASCADE ON DELETE CASCADE,
    id_accion   TEXT NOT NULL REFERENCES acciones(id) ON DELETE CASCADE,
    fecha       TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id_usuario, id_accion)
);

-- ---------- INICIATIVAS VECINALES ----------
CREATE TABLE iniciativas (
    id                      TEXT PRIMARY KEY,
    id_barrio               TEXT NOT NULL REFERENCES barrios(id)  ON UPDATE CASCADE,
    id_creador              TEXT NOT NULL REFERENCES usuarios(id) ON UPDATE CASCADE ON DELETE CASCADE,
    titulo                  VARCHAR(100) NOT NULL CHECK (char_length(btrim(titulo)) >= 1),
    descripcion             VARCHAR(400) NOT NULL CHECK (char_length(btrim(descripcion)) >= 1),
    meta                    VARCHAR(200) NOT NULL CHECK (char_length(btrim(meta)) >= 1),
    estado                  TEXT NOT NULL CHECK (estado IN ('Propuesta', 'En curso', 'Cumplida', 'Cancelada')),
    temperatura_al_cumplir  DOUBLE PRECISION,
    fecha_creacion          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_iniciativas_barrio  ON iniciativas(id_barrio);
CREATE INDEX idx_iniciativas_creador ON iniciativas(id_creador);

-- Vecinos que se "sumaron". El campo participantes de la API = COUNT(*) de esta tabla.
CREATE TABLE iniciativa_participantes (
    id_iniciativa  TEXT NOT NULL REFERENCES iniciativas(id) ON DELETE CASCADE,
    id_usuario     TEXT NOT NULL REFERENCES usuarios(id) ON UPDATE CASCADE ON DELETE CASCADE,
    fecha          TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id_iniciativa, id_usuario)
);

-- ---------- ALERTAS DE BARRIO (máx. 1 por barrio, dura 30 min) ----------
CREATE TABLE alertas (
    id         TEXT PRIMARY KEY,
    id_barrio  TEXT NOT NULL UNIQUE REFERENCES barrios(id) ON UPDATE CASCADE ON DELETE CASCADE,
    id_usuario TEXT REFERENCES usuarios(id) ON DELETE SET NULL,
    inicio     TIMESTAMPTZ NOT NULL,
    expira     TIMESTAMPTZ NOT NULL,
    CHECK (expira > inicio)
);