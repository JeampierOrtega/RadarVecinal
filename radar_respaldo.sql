--
-- PostgreSQL database dump
--

\restrict eCgp1N9fh5Jrf1AEH6h1cQ1sg98gkjDM0OY0ktlPQhMFM7htbyajOzt4KwvdDZk

-- Dumped from database version 18.6 (Debian 18.6-1.pgdg13+2)
-- Dumped by pg_dump version 18.6 (Debian 18.6-1.pgdg13+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE IF EXISTS ONLY public.votos_reporte DROP CONSTRAINT IF EXISTS votos_reporte_id_usuario_fkey;
ALTER TABLE IF EXISTS ONLY public.votos_reporte DROP CONSTRAINT IF EXISTS votos_reporte_id_reporte_fkey;
ALTER TABLE IF EXISTS ONLY public.usuarios DROP CONSTRAINT IF EXISTS usuarios_id_barrio_fkey;
ALTER TABLE IF EXISTS ONLY public.reportes DROP CONSTRAINT IF EXISTS reportes_id_usuario_fkey;
ALTER TABLE IF EXISTS ONLY public.reportes DROP CONSTRAINT IF EXISTS reportes_id_barrio_fkey;
ALTER TABLE IF EXISTS ONLY public.noticias_leidas DROP CONSTRAINT IF EXISTS noticias_leidas_id_usuario_fkey;
ALTER TABLE IF EXISTS ONLY public.noticias_leidas DROP CONSTRAINT IF EXISTS noticias_leidas_id_accion_fkey;
ALTER TABLE IF EXISTS ONLY public.iniciativas DROP CONSTRAINT IF EXISTS iniciativas_id_creador_fkey;
ALTER TABLE IF EXISTS ONLY public.iniciativas DROP CONSTRAINT IF EXISTS iniciativas_id_barrio_fkey;
ALTER TABLE IF EXISTS ONLY public.iniciativa_participantes DROP CONSTRAINT IF EXISTS iniciativa_participantes_id_usuario_fkey;
ALTER TABLE IF EXISTS ONLY public.iniciativa_participantes DROP CONSTRAINT IF EXISTS iniciativa_participantes_id_iniciativa_fkey;
ALTER TABLE IF EXISTS ONLY public.denuncias_reporte DROP CONSTRAINT IF EXISTS denuncias_reporte_id_usuario_fkey;
ALTER TABLE IF EXISTS ONLY public.denuncias_reporte DROP CONSTRAINT IF EXISTS denuncias_reporte_id_reporte_fkey;
ALTER TABLE IF EXISTS ONLY public.codigos_barrio DROP CONSTRAINT IF EXISTS codigos_barrio_id_barrio_fkey;
ALTER TABLE IF EXISTS ONLY public.alertas DROP CONSTRAINT IF EXISTS alertas_id_usuario_fkey;
ALTER TABLE IF EXISTS ONLY public.alertas DROP CONSTRAINT IF EXISTS alertas_id_barrio_fkey;
ALTER TABLE IF EXISTS ONLY public.acciones DROP CONSTRAINT IF EXISTS acciones_id_reporte_fkey;
ALTER TABLE IF EXISTS ONLY public.acciones DROP CONSTRAINT IF EXISTS acciones_id_barrio_fkey;
ALTER TABLE IF EXISTS ONLY public.acciones DROP CONSTRAINT IF EXISTS acciones_id_autoridad_fkey;
DROP INDEX IF EXISTS public.idx_usuarios_estado;
DROP INDEX IF EXISTS public.idx_usuarios_barrio;
DROP INDEX IF EXISTS public.idx_reportes_usuario;
DROP INDEX IF EXISTS public.idx_reportes_fecha;
DROP INDEX IF EXISTS public.idx_reportes_estado;
DROP INDEX IF EXISTS public.idx_reportes_barrio;
DROP INDEX IF EXISTS public.idx_iniciativas_creador;
DROP INDEX IF EXISTS public.idx_iniciativas_barrio;
DROP INDEX IF EXISTS public.idx_codigos_barrio_barrio;
DROP INDEX IF EXISTS public.idx_acciones_reporte;
DROP INDEX IF EXISTS public.idx_acciones_estado;
DROP INDEX IF EXISTS public.idx_acciones_barrio;
ALTER TABLE IF EXISTS ONLY public.votos_reporte DROP CONSTRAINT IF EXISTS votos_reporte_pkey;
ALTER TABLE IF EXISTS ONLY public.usuarios DROP CONSTRAINT IF EXISTS usuarios_pkey;
ALTER TABLE IF EXISTS ONLY public.usuarios DROP CONSTRAINT IF EXISTS usuarios_dni_key;
ALTER TABLE IF EXISTS ONLY public.usuarios DROP CONSTRAINT IF EXISTS usuarios_correo_key;
ALTER TABLE IF EXISTS ONLY public.reportes DROP CONSTRAINT IF EXISTS reportes_pkey;
ALTER TABLE IF EXISTS ONLY public.noticias_leidas DROP CONSTRAINT IF EXISTS noticias_leidas_pkey;
ALTER TABLE IF EXISTS ONLY public.iniciativas DROP CONSTRAINT IF EXISTS iniciativas_pkey;
ALTER TABLE IF EXISTS ONLY public.iniciativa_participantes DROP CONSTRAINT IF EXISTS iniciativa_participantes_pkey;
ALTER TABLE IF EXISTS ONLY public.denuncias_reporte DROP CONSTRAINT IF EXISTS denuncias_reporte_pkey;
ALTER TABLE IF EXISTS ONLY public.codigos_barrio DROP CONSTRAINT IF EXISTS codigos_barrio_pkey;
ALTER TABLE IF EXISTS ONLY public.codigos_barrio DROP CONSTRAINT IF EXISTS codigos_barrio_codigo_key;
ALTER TABLE IF EXISTS ONLY public.barrios DROP CONSTRAINT IF EXISTS barrios_pkey;
ALTER TABLE IF EXISTS ONLY public.barrios DROP CONSTRAINT IF EXISTS barrios_nombre_key;
ALTER TABLE IF EXISTS ONLY public.alertas DROP CONSTRAINT IF EXISTS alertas_pkey;
ALTER TABLE IF EXISTS ONLY public.alertas DROP CONSTRAINT IF EXISTS alertas_id_barrio_key;
ALTER TABLE IF EXISTS ONLY public.acciones DROP CONSTRAINT IF EXISTS acciones_pkey;
DROP VIEW IF EXISTS public.v_usuarios;
DROP VIEW IF EXISTS public.v_resumen_barrios;
DROP VIEW IF EXISTS public.v_reportes;
DROP VIEW IF EXISTS public.v_iniciativas;
DROP VIEW IF EXISTS public.v_conteo_tablas;
DROP TABLE IF EXISTS public.votos_reporte;
DROP VIEW IF EXISTS public.v_alertas_activas;
DROP VIEW IF EXISTS public.v_acciones;
DROP TABLE IF EXISTS public.usuarios;
DROP SEQUENCE IF EXISTS public.seq_usuarios_vecinos;
DROP SEQUENCE IF EXISTS public.seq_usuarios_municipalidad;
DROP SEQUENCE IF EXISTS public.seq_reportes;
DROP SEQUENCE IF EXISTS public.seq_iniciativas;
DROP SEQUENCE IF EXISTS public.seq_alertas;
DROP SEQUENCE IF EXISTS public.seq_acciones;
DROP TABLE IF EXISTS public.reportes;
DROP TABLE IF EXISTS public.noticias_leidas;
DROP TABLE IF EXISTS public.iniciativas;
DROP TABLE IF EXISTS public.iniciativa_participantes;
DROP TABLE IF EXISTS public.denuncias_reporte;
DROP TABLE IF EXISTS public.codigos_barrio;
DROP TABLE IF EXISTS public.barrios;
DROP TABLE IF EXISTS public.alertas;
DROP TABLE IF EXISTS public.acciones;
SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: acciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.acciones (
    id text NOT NULL,
    id_barrio text NOT NULL,
    id_autoridad text NOT NULL,
    institucion text NOT NULL,
    tipo text NOT NULL,
    titulo character varying(100) NOT NULL,
    descripcion character varying(400) NOT NULL,
    fecha timestamp with time zone NOT NULL,
    estado text NOT NULL,
    fotos text[] DEFAULT '{}'::text[] NOT NULL,
    id_reporte text,
    fecha_registro timestamp with time zone DEFAULT now() NOT NULL,
    temperatura_al_completar double precision,
    CONSTRAINT acciones_descripcion_check CHECK ((char_length(btrim((descripcion)::text)) >= 1)),
    CONSTRAINT acciones_estado_check CHECK ((estado = ANY (ARRAY['Planificada'::text, 'En ejecución'::text, 'Completada'::text]))),
    CONSTRAINT acciones_fotos_check CHECK ((cardinality(fotos) <= 4)),
    CONSTRAINT acciones_tipo_check CHECK ((tipo = ANY (ARRAY['Patrullaje de serenazgo'::text, 'Operativo con la policía'::text, 'Alumbrado'::text, 'Campaña de prevención'::text, 'Otro'::text]))),
    CONSTRAINT acciones_titulo_check CHECK ((char_length(btrim((titulo)::text)) >= 1))
);


--
-- Name: alertas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alertas (
    id text NOT NULL,
    id_barrio text NOT NULL,
    id_usuario text,
    inicio timestamp with time zone NOT NULL,
    expira timestamp with time zone NOT NULL,
    CONSTRAINT alertas_check CHECK ((expira > inicio))
);


--
-- Name: barrios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.barrios (
    id text NOT NULL,
    nombre text NOT NULL,
    poligono jsonb NOT NULL,
    CONSTRAINT barrios_poligono_check CHECK ((jsonb_typeof(poligono) = 'array'::text))
);


--
-- Name: codigos_barrio; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.codigos_barrio (
    id text NOT NULL,
    id_barrio text NOT NULL,
    codigo text NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    fecha_expiracion timestamp with time zone
);


--
-- Name: denuncias_reporte; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.denuncias_reporte (
    id_reporte text NOT NULL,
    id_usuario text NOT NULL,
    fecha timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: iniciativa_participantes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.iniciativa_participantes (
    id_iniciativa text NOT NULL,
    id_usuario text NOT NULL,
    fecha timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: iniciativas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.iniciativas (
    id text NOT NULL,
    id_barrio text NOT NULL,
    id_creador text NOT NULL,
    titulo character varying(100) NOT NULL,
    descripcion character varying(400) NOT NULL,
    meta character varying(200) NOT NULL,
    estado text NOT NULL,
    temperatura_al_cumplir double precision,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT iniciativas_descripcion_check CHECK ((char_length(btrim((descripcion)::text)) >= 1)),
    CONSTRAINT iniciativas_estado_check CHECK ((estado = ANY (ARRAY['Propuesta'::text, 'En curso'::text, 'Cumplida'::text, 'Cancelada'::text]))),
    CONSTRAINT iniciativas_meta_check CHECK ((char_length(btrim((meta)::text)) >= 1)),
    CONSTRAINT iniciativas_titulo_check CHECK ((char_length(btrim((titulo)::text)) >= 1))
);


--
-- Name: noticias_leidas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.noticias_leidas (
    id_usuario text NOT NULL,
    id_accion text NOT NULL,
    fecha timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: reportes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reportes (
    id text NOT NULL,
    id_usuario text NOT NULL,
    id_barrio text NOT NULL,
    lat double precision NOT NULL,
    lng double precision NOT NULL,
    tipo text NOT NULL,
    gravedad smallint NOT NULL,
    descripcion character varying(280) NOT NULL,
    fecha timestamp with time zone DEFAULT now() NOT NULL,
    estado text DEFAULT 'activo'::text NOT NULL,
    CONSTRAINT reportes_descripcion_check CHECK ((char_length(btrim((descripcion)::text)) >= 1)),
    CONSTRAINT reportes_estado_check CHECK ((estado = ANY (ARRAY['activo'::text, 'confirmado'::text, 'falso'::text, 'archivado'::text]))),
    CONSTRAINT reportes_gravedad_check CHECK ((gravedad >= 0)),
    CONSTRAINT reportes_lat_check CHECK (((lat >= ('-90'::integer)::double precision) AND (lat <= (90)::double precision))),
    CONSTRAINT reportes_lng_check CHECK (((lng >= ('-180'::integer)::double precision) AND (lng <= (180)::double precision))),
    CONSTRAINT reportes_tipo_check CHECK ((tipo = ANY (ARRAY['asalto_robo'::text, 'pandillaje'::text, 'alcohol_drogas'::text, 'falta_alumbrado'::text, 'actividad_sospechosa'::text, 'otro'::text])))
);


--
-- Name: seq_acciones; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.seq_acciones
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: seq_alertas; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.seq_alertas
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: seq_iniciativas; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.seq_iniciativas
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: seq_reportes; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.seq_reportes
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: seq_usuarios_municipalidad; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.seq_usuarios_municipalidad
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: seq_usuarios_vecinos; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.seq_usuarios_vecinos
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuarios (
    id text NOT NULL,
    nombre character varying(100) NOT NULL,
    dni character(8) NOT NULL,
    correo text NOT NULL,
    clave_hash text NOT NULL,
    rol text NOT NULL,
    id_barrio text,
    estado text DEFAULT 'Pendiente'::text NOT NULL,
    strikes smallint DEFAULT 0 NOT NULL,
    suspendido_hasta timestamp with time zone,
    motivo_sancion text,
    fecha_registro timestamp with time zone DEFAULT now() NOT NULL,
    institucion text,
    CONSTRAINT usuarios_correo_check CHECK ((correo ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'::text)),
    CONSTRAINT usuarios_dni_check CHECK ((dni ~ '^[0-9]{8}$'::text)),
    CONSTRAINT usuarios_estado_check CHECK ((estado = ANY (ARRAY['Pendiente'::text, 'Verificado'::text, 'Rechazado'::text, 'Suspendido'::text, 'Baneado'::text]))),
    CONSTRAINT usuarios_nombre_check CHECK ((char_length((nombre)::text) >= 3)),
    CONSTRAINT usuarios_rol_check CHECK ((rol = ANY (ARRAY['vecino'::text, 'municipalidad'::text]))),
    CONSTRAINT usuarios_strikes_check CHECK ((strikes >= 0))
);


--
-- Name: v_acciones; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_acciones AS
 SELECT a.id,
    a.fecha,
    b.nombre AS barrio,
    a.tipo,
    a.titulo,
    a.estado,
    a.institucion,
    a.id_reporte,
    cardinality(a.fotos) AS num_fotos,
    a.temperatura_al_completar,
    a.fecha_registro
   FROM (public.acciones a
     JOIN public.barrios b ON ((b.id = a.id_barrio)))
  ORDER BY a.fecha DESC;


--
-- Name: v_alertas_activas; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_alertas_activas AS
 SELECT a.id,
    b.nombre AS barrio,
    a.inicio,
    a.expira,
    round((EXTRACT(epoch FROM (a.expira - now())) / 60.0), 1) AS minutos_restantes,
    a.id_usuario,
    u.nombre AS autor_nombre,
    u.dni AS autor_dni
   FROM ((public.alertas a
     JOIN public.barrios b ON ((b.id = a.id_barrio)))
     LEFT JOIN public.usuarios u ON ((u.id = a.id_usuario)))
  WHERE (a.expira > now())
  ORDER BY a.expira;


--
-- Name: votos_reporte; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.votos_reporte (
    id_reporte text NOT NULL,
    id_usuario text NOT NULL,
    voto text NOT NULL,
    fecha timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT votos_reporte_voto_check CHECK ((voto = ANY (ARRAY['confirmo'::text, 'incorrecto'::text])))
);


--
-- Name: v_conteo_tablas; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_conteo_tablas AS
 SELECT 'barrios'::text AS tabla,
    count(*) AS filas
   FROM public.barrios
UNION ALL
 SELECT 'codigos_barrio'::text AS tabla,
    count(*) AS filas
   FROM public.codigos_barrio
UNION ALL
 SELECT 'usuarios'::text AS tabla,
    count(*) AS filas
   FROM public.usuarios
UNION ALL
 SELECT 'reportes'::text AS tabla,
    count(*) AS filas
   FROM public.reportes
UNION ALL
 SELECT 'votos_reporte'::text AS tabla,
    count(*) AS filas
   FROM public.votos_reporte
UNION ALL
 SELECT 'denuncias_reporte'::text AS tabla,
    count(*) AS filas
   FROM public.denuncias_reporte
UNION ALL
 SELECT 'acciones'::text AS tabla,
    count(*) AS filas
   FROM public.acciones
UNION ALL
 SELECT 'noticias_leidas'::text AS tabla,
    count(*) AS filas
   FROM public.noticias_leidas
UNION ALL
 SELECT 'iniciativas'::text AS tabla,
    count(*) AS filas
   FROM public.iniciativas
UNION ALL
 SELECT 'iniciativa_participantes'::text AS tabla,
    count(*) AS filas
   FROM public.iniciativa_participantes
UNION ALL
 SELECT 'alertas'::text AS tabla,
    count(*) AS filas
   FROM public.alertas;


--
-- Name: v_iniciativas; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_iniciativas AS
 SELECT i.id,
    b.nombre AS barrio,
    i.titulo,
    i.meta,
    i.estado,
    u.nombre AS creador,
    ( SELECT count(*) AS count
           FROM public.iniciativa_participantes p
          WHERE (p.id_iniciativa = i.id)) AS participantes,
    i.temperatura_al_cumplir,
    i.fecha_creacion
   FROM ((public.iniciativas i
     JOIN public.barrios b ON ((b.id = i.id_barrio)))
     JOIN public.usuarios u ON ((u.id = i.id_creador)))
  ORDER BY i.fecha_creacion DESC;


--
-- Name: v_reportes; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_reportes AS
 SELECT r.id,
    r.fecha,
    b.nombre AS barrio,
    r.tipo,
    r.gravedad,
    r.estado,
    r.descripcion,
    u.nombre AS autor,
    r.lat,
    r.lng,
    ( SELECT count(*) AS count
           FROM public.votos_reporte v
          WHERE ((v.id_reporte = r.id) AND (v.voto = 'confirmo'::text))) AS confirmaciones,
    ( SELECT count(*) AS count
           FROM public.votos_reporte v
          WHERE ((v.id_reporte = r.id) AND (v.voto = 'incorrecto'::text))) AS incorrectos,
    ( SELECT count(*) AS count
           FROM public.denuncias_reporte d
          WHERE (d.id_reporte = r.id)) AS denuncias
   FROM ((public.reportes r
     JOIN public.barrios b ON ((b.id = r.id_barrio)))
     JOIN public.usuarios u ON ((u.id = r.id_usuario)))
  ORDER BY r.fecha DESC;


--
-- Name: v_resumen_barrios; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_resumen_barrios AS
 SELECT id,
    nombre AS barrio,
    ( SELECT count(*) AS count
           FROM public.usuarios u
          WHERE ((u.id_barrio = b.id) AND (u.rol = 'vecino'::text))) AS vecinos,
    ( SELECT count(*) AS count
           FROM public.reportes r
          WHERE (r.id_barrio = b.id)) AS reportes,
    ( SELECT count(*) AS count
           FROM public.reportes r
          WHERE ((r.id_barrio = b.id) AND (r.estado = ANY (ARRAY['activo'::text, 'confirmado'::text])))) AS reportes_vigentes,
    ( SELECT count(*) AS count
           FROM public.acciones a
          WHERE (a.id_barrio = b.id)) AS acciones,
    ( SELECT count(*) AS count
           FROM public.iniciativas i
          WHERE (i.id_barrio = b.id)) AS iniciativas
   FROM public.barrios b
  ORDER BY (length(id)), id;


--
-- Name: v_usuarios; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_usuarios AS
 SELECT u.id,
    u.nombre,
    u.dni,
    u.correo,
    u.rol,
    u.estado,
    u.strikes,
    u.suspendido_hasta,
    u.motivo_sancion,
    b.nombre AS barrio,
    u.institucion,
    u.fecha_registro
   FROM (public.usuarios u
     LEFT JOIN public.barrios b ON ((b.id = u.id_barrio)))
  ORDER BY u.fecha_registro DESC;


--
-- Data for Name: acciones; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.acciones VALUES ('a2', 'b1', 'm1', 'Municipalidad', 'Alumbrado', 'Reparación de postes', 'Se cambiaron 12 luminarias LED.', '2026-11-18 01:45:40.596354+00', 'Completada', '{}', NULL, '2026-11-18 01:45:40.596354+00', 9.1);
INSERT INTO public.acciones VALUES ('a3', 'b2', 'm1', 'Municipalidad', 'Otro', 'Limpieza de terreno baldío', 'Retiro de maleza y desmonte.', '2026-11-27 01:45:40.596354+00', 'Planificada', '{}', NULL, '2026-11-27 01:45:40.596354+00', NULL);
INSERT INTO public.acciones VALUES ('a5', 'b4', 'm1', 'Municipalidad', 'Otro', 'Instalación de cámara', 'Cámara conectada a la central.', '2026-11-09 01:45:40.596354+00', 'Completada', '{}', NULL, '2026-11-09 01:45:40.596354+00', 8.4);
INSERT INTO public.acciones VALUES ('a6', 'b5', 'm1', 'Municipalidad', 'Campaña de prevención', 'Charla de prevención', 'Taller con las juntas vecinales.', '2026-12-01 01:45:40.596354+00', 'Planificada', '{}', NULL, '2026-12-01 01:45:40.596354+00', NULL);
INSERT INTO public.acciones VALUES ('a9', 'b9', 'm1', 'Municipalidad', 'Campaña de prevención', 'Feria de seguridad vecinal', 'Feria informativa en la plaza del barrio.', '2026-11-29 01:45:40.596354+00', 'Planificada', '{}', NULL, '2026-11-29 01:45:40.596354+00', NULL);
INSERT INTO public.acciones VALUES ('a10', 'b6', 'm1', 'Municipalidad', 'Alumbrado', 'Ampliación de red eléctrica', 'Nuevos postes en el pasaje alto.', '2026-12-02 01:45:40.596354+00', 'Planificada', '{}', NULL, '2026-12-02 01:45:40.596354+00', NULL);
INSERT INTO public.acciones VALUES ('a11', 'b9', 'm1', 'Municipalidad', 'Otro', 'Mantenimiento de cámaras', 'Se repararon las cámaras de la avenida.', '2026-11-04 01:45:40.596354+00', 'Completada', '{}', NULL, '2026-11-04 01:45:40.596354+00', 41.2);
INSERT INTO public.acciones VALUES ('a13', 'b3', 'm1', 'Municipalidad', 'Alumbrado', 'Cambio de 20 luminarias', 'Intervención completa en el sector.', '2026-11-19 01:45:40.596354+00', 'Completada', '{}', NULL, '2026-11-19 01:45:40.596354+00', 21.7);
INSERT INTO public.acciones VALUES ('a14', 'b1', 'm1', 'Municipalidad', 'Operativo con la policía', 'Control de identidad', 'Operativo conjunto en la avenida principal.', '2026-11-16 01:45:40.596354+00', 'Completada', '{}', NULL, '2026-11-16 01:45:40.596354+00', 14.3);
INSERT INTO public.acciones VALUES ('a15', 'b2', 'm1', 'Municipalidad', 'Campaña de prevención', 'Taller para juntas vecinales', 'Capacitación sobre rutas de denuncia.', '2026-12-04 01:45:40.596354+00', 'Planificada', '{}', NULL, '2026-12-04 01:45:40.596354+00', NULL);
INSERT INTO public.acciones VALUES ('a18', 'b8', 'm1', 'Municipalidad', 'Otro', 'Señalización de calles', 'Nuevos letreros y señalética peatonal.', '2026-12-06 01:45:40.596354+00', 'Planificada', '{}', NULL, '2026-12-06 01:45:40.596354+00', NULL);
INSERT INTO public.acciones VALUES ('a8', 'b7', 'm1', 'Municipalidad', 'Alumbrado', 'Reposición de luminarias en San Antonio', 'Se repusieron 18 luminarias LED.', '2026-11-15 01:45:40.596354+00', 'Completada', '{}', NULL, '2026-11-15 01:45:40.596354+00', 26.4);
INSERT INTO public.acciones VALUES ('a1', 'b1', 'm1', 'Municipalidad', 'Patrullaje de serenazgo', 'Patrullaje reforzado', 'Se incrementaron rondas de 18:00 a 02:00.', '2026-11-22 01:45:40.596354+00', 'En ejecución', '{}', 'r1', '2026-11-22 01:45:40.596354+00', NULL);
INSERT INTO public.acciones VALUES ('a4', 'b3', 'm1', 'Municipalidad', 'Patrullaje de serenazgo', 'Punto fijo de serenazgo', 'Unidad fija en la esquina del parque.', '2026-11-23 01:45:40.596354+00', 'En ejecución', '{}', 'r25', '2026-11-23 01:45:40.596354+00', NULL);
INSERT INTO public.acciones VALUES ('a7', 'b6', 'm1', 'Municipalidad', 'Patrullaje de serenazgo', 'Patrullaje disuasivo en Cajas Chico', 'Rondas por las calles principales del sector.', '2026-11-20 01:45:40.596354+00', 'En ejecución', '{}', 'r68', '2026-11-20 01:45:40.596354+00', NULL);
INSERT INTO public.acciones VALUES ('a12', 'b5', 'm1', 'Municipalidad', 'Patrullaje de serenazgo', 'Refuerzo de vigilancia', 'Patrulla adicional los fines de semana.', '2026-11-22 01:45:40.596354+00', 'En ejecución', '{}', 'r52', '2026-11-22 01:45:40.596354+00', NULL);
INSERT INTO public.acciones VALUES ('a16', 'b4', 'm1', 'Municipalidad', 'Alumbrado', 'Reparación de poste averiado', 'El poste de la esquina ya está operativo.', '2026-11-21 01:45:40.596354+00', 'En ejecución', '{}', 'r42', '2026-11-21 01:45:40.596354+00', NULL);
INSERT INTO public.acciones VALUES ('a17', 'b8', 'm1', 'Municipalidad', 'Operativo con la policía', 'Operativo en Uñas', 'Patrullaje conjunto en zonas críticas.', '2026-11-26 01:45:40.596354+00', 'Planificada', '{}', 'r90', '2026-11-26 01:45:40.596354+00', NULL);


--
-- Data for Name: alertas; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: barrios; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.barrios VALUES ('b1', 'Torre Torre', '[[-12.06046, -75.18428], [-12.06004, -75.18354], [-12.05928, -75.18378], [-12.0584, -75.18382], [-12.0576, -75.18362], [-12.05688, -75.18318], [-12.05572, -75.1829], [-12.054, -75.18298], [-12.05356, -75.1829], [-12.0528, -75.18258], [-12.05116, -75.18142], [-12.05016, -75.18154], [-12.04986, -75.18248], [-12.04954, -75.18296], [-12.04894, -75.18352], [-12.04894, -75.1836], [-12.04954, -75.18436], [-12.04966, -75.18468], [-12.0497, -75.18604], [-12.0503, -75.18772], [-12.04994, -75.18852], [-12.04994, -75.1888], [-12.0509, -75.19144], [-12.0509, -75.19204], [-12.05108, -75.19218], [-12.05148, -75.19214], [-12.05396, -75.19098], [-12.05432, -75.1909], [-12.05496, -75.19098], [-12.05584, -75.19134], [-12.05612, -75.19138], [-12.05726, -75.18912], [-12.05792, -75.18874], [-12.0593, -75.18812], [-12.06046, -75.18428]]');
INSERT INTO public.barrios VALUES ('b2', 'Palián', '[[-12.04434, -75.19376], [-12.04398, -75.19248], [-12.04402, -75.1918], [-12.04374, -75.18984], [-12.04374, -75.18956], [-12.0439, -75.18928], [-12.0439, -75.18908], [-12.04378, -75.18884], [-12.04262, -75.18776], [-12.04232, -75.18726], [-12.0416, -75.18754], [-12.04116, -75.18762], [-12.04048, -75.18762], [-12.04004, -75.18754], [-12.0394, -75.18726], [-12.03844, -75.18734], [-12.03788, -75.18766], [-12.03722, -75.18784], [-12.03714, -75.1886], [-12.0369, -75.18908], [-12.03664, -75.18938], [-12.03428, -75.18994], [-12.03374, -75.19044], [-12.03134, -75.19436], [-12.03114, -75.1948], [-12.0311, -75.19556], [-12.0303, -75.19632], [-12.03006, -75.19676], [-12.03006, -75.19696], [-12.0308, -75.19726], [-12.03162, -75.19796], [-12.03194, -75.19844], [-12.0324, -75.19938], [-12.03384, -75.19894], [-12.035, -75.1989], [-12.04028, -75.1995], [-12.04068, -75.1991], [-12.04146, -75.19889], [-12.04206, -75.19882], [-12.04289, -75.19901], [-12.04314, -75.1968], [-12.04298, -75.1962], [-12.04334, -75.19564], [-12.04358, -75.19484], [-12.0443, -75.19408], [-12.04434, -75.19376]]');
INSERT INTO public.barrios VALUES ('b3', 'San Carlos', '[[-12.07062, -75.2014], [-12.07024, -75.20082], [-12.06924, -75.20026], [-12.06828, -75.19958], [-12.06764, -75.19926], [-12.06712, -75.1991], [-12.06584, -75.1991], [-12.06188, -75.19858], [-12.06148, -75.19842], [-12.06068, -75.19782], [-12.05932, -75.1977], [-12.05864, -75.19738], [-12.05812, -75.19706], [-12.0577, -75.19664], [-12.05748, -75.1963], [-12.05736, -75.1963], [-12.05646, -75.19724], [-12.05446, -75.19988], [-12.0541, -75.20052], [-12.05354, -75.20108], [-12.05278, -75.2026], [-12.05118, -75.20484], [-12.05118, -75.20496], [-12.05196, -75.20558], [-12.05288, -75.20578], [-12.0538, -75.2063], [-12.05472, -75.2067], [-12.05512, -75.20698], [-12.05564, -75.2075], [-12.05648, -75.20798], [-12.05748, -75.20794], [-12.05816, -75.2081], [-12.05868, -75.20834], [-12.0595, -75.20904], [-12.05982, -75.20952], [-12.06026, -75.21044], [-12.06044, -75.21046], [-12.06136, -75.2097], [-12.062, -75.20934], [-12.0628, -75.20914], [-12.06368, -75.20918], [-12.06394, -75.20788], [-12.06408, -75.20762], [-12.06904, -75.20522], [-12.06926, -75.20488], [-12.0699, -75.20284], [-12.07062, -75.2014]]');
INSERT INTO public.barrios VALUES ('b4', 'Zona Monumental', '[[-12.07702, -75.21068], [-12.0745, -75.20536], [-12.07434, -75.20476], [-12.0743, -75.20428], [-12.07438, -75.20368], [-12.0736, -75.20342], [-12.07316, -75.20318], [-12.07072, -75.2015], [-12.07054, -75.20156], [-12.07002, -75.20256], [-12.06918, -75.20508], [-12.0688, -75.20534], [-12.06408, -75.20762], [-12.06394, -75.20788], [-12.0637, -75.20912], [-12.06372, -75.20922], [-12.06424, -75.20934], [-12.06488, -75.2097], [-12.06562, -75.21044], [-12.06858, -75.21576], [-12.06864, -75.21582], [-12.06952, -75.2159], [-12.07036, -75.2163], [-12.07436, -75.21406], [-12.07492, -75.2139], [-12.07572, -75.21386], [-12.07574, -75.21284], [-12.07598, -75.21204], [-12.07638, -75.2114], [-12.07702, -75.21084], [-12.07702, -75.21068]]');
INSERT INTO public.barrios VALUES ('b5', 'Ocopilla', '[[-12.07766, -75.20036], [-12.07274, -75.18988], [-12.07204, -75.1897], [-12.0714, -75.18934], [-12.07008, -75.18802], [-12.06908, -75.1875], [-12.0685, -75.18696], [-12.06802, -75.18616], [-12.06638, -75.182], [-12.064, -75.18026], [-12.0638, -75.1803], [-12.06136, -75.1823], [-12.06064, -75.18314], [-12.0601, -75.18348], [-12.0601, -75.1836], [-12.06042, -75.18416], [-12.06046, -75.18444], [-12.0593, -75.18812], [-12.05792, -75.18874], [-12.05726, -75.18912], [-12.05622, -75.19128], [-12.0561, -75.1914], [-12.05638, -75.19368], [-12.05726, -75.19548], [-12.0575, -75.19636], [-12.05812, -75.19706], [-12.05864, -75.19738], [-12.05932, -75.1977], [-12.06068, -75.19782], [-12.06148, -75.19842], [-12.06188, -75.19858], [-12.06584, -75.1991], [-12.06712, -75.1991], [-12.06764, -75.19926], [-12.06828, -75.19958], [-12.06924, -75.20026], [-12.07024, -75.20082], [-12.07064, -75.20146], [-12.07316, -75.20318], [-12.0736, -75.20342], [-12.0742, -75.20362], [-12.07442, -75.20356], [-12.0745, -75.2032], [-12.07478, -75.20264], [-12.07544, -75.2019], [-12.07764, -75.20054], [-12.07766, -75.20036]]');
INSERT INTO public.barrios VALUES ('b6', 'Cajas Chico', '[[-12.0829, -75.22784], [-12.0801, -75.22108], [-12.0799, -75.22028], [-12.0797, -75.21864], [-12.07888, -75.21634], [-12.07796, -75.21626], [-12.0772, -75.21594], [-12.0768, -75.21566], [-12.07638, -75.21524], [-12.07606, -75.21476], [-12.07576, -75.21386], [-12.0752, -75.21386], [-12.07436, -75.21406], [-12.07046, -75.21628], [-12.07046, -75.21636], [-12.0711, -75.21692], [-12.0713, -75.2172], [-12.07338, -75.22096], [-12.07362, -75.22176], [-12.0737, -75.22272], [-12.07548, -75.22714], [-12.07624, -75.22722], [-12.07696, -75.22754], [-12.0778, -75.22754], [-12.07844, -75.22766], [-12.0792, -75.22798], [-12.07988, -75.22854], [-12.08004, -75.22854], [-12.08052, -75.2283], [-12.08108, -75.22814], [-12.0824, -75.2281], [-12.0828, -75.22802], [-12.0829, -75.22796], [-12.0829, -75.22784]]');
INSERT INTO public.barrios VALUES ('b7', 'San Antonio', '[[-12.05742, -75.19612], [-12.05726, -75.19548], [-12.05638, -75.19368], [-12.0561, -75.19144], [-12.05496, -75.19098], [-12.05432, -75.1909], [-12.05396, -75.19098], [-12.05136, -75.19218], [-12.05108, -75.19218], [-12.05092, -75.19206], [-12.0504, -75.19198], [-12.04916, -75.19134], [-12.04852, -75.1911], [-12.04838, -75.19124], [-12.04838, -75.19156], [-12.04874, -75.19372], [-12.0487, -75.19484], [-12.0486, -75.19518], [-12.04824, -75.19518], [-12.04432, -75.19402], [-12.04358, -75.19484], [-12.04342, -75.19544], [-12.04298, -75.1962], [-12.04298, -75.19636], [-12.04314, -75.1968], [-12.04289, -75.19901], [-12.04413, -75.19894], [-12.04473, -75.19899], [-12.04562, -75.19932], [-12.0466, -75.20042], [-12.04736, -75.2005], [-12.04792, -75.20066], [-12.0488, -75.20118], [-12.04922, -75.2016], [-12.04954, -75.20208], [-12.05086, -75.20472], [-12.05104, -75.20486], [-12.05116, -75.20486], [-12.05278, -75.2026], [-12.05354, -75.20108], [-12.0541, -75.20052], [-12.05458, -75.19972], [-12.05646, -75.19724], [-12.05742, -75.19624], [-12.05742, -75.19612]]');
INSERT INTO public.barrios VALUES ('b8', 'Uñas', '[[-12.03722, -75.18792], [-12.03716, -75.18786], [-12.03644, -75.18786], [-12.036, -75.18778], [-12.03552, -75.18758], [-12.03424, -75.18746], [-12.03332, -75.18706], [-12.03272, -75.18662], [-12.03222, -75.18612], [-12.0314, -75.18474], [-12.03064, -75.18458], [-12.02984, -75.1841], [-12.02938, -75.18364], [-12.0286, -75.1825], [-12.0252, -75.18186], [-12.02402, -75.18568], [-12.02394, -75.18672], [-12.02366, -75.18748], [-12.02334, -75.18796], [-12.02292, -75.18838], [-12.0212, -75.18974], [-12.0211, -75.18984], [-12.0211, -75.18996], [-12.02286, -75.19348], [-12.025, -75.19646], [-12.02784, -75.19718], [-12.02848, -75.19694], [-12.02892, -75.19686], [-12.0296, -75.19686], [-12.03, -75.19694], [-12.0303, -75.19632], [-12.0311, -75.19556], [-12.03114, -75.1948], [-12.03134, -75.19436], [-12.03374, -75.19044], [-12.03428, -75.18994], [-12.03664, -75.18938], [-12.0369, -75.18908], [-12.03714, -75.1886], [-12.03722, -75.18792]]');
INSERT INTO public.barrios VALUES ('b9', 'Chorrillos', '[[-12.0509, -75.19144], [-12.04994, -75.1888], [-12.04994, -75.18852], [-12.05026, -75.18784], [-12.05026, -75.1876], [-12.0497, -75.18604], [-12.0497, -75.18492], [-12.04962, -75.18452], [-12.04892, -75.18358], [-12.0488, -75.18358], [-12.04832, -75.18386], [-12.04752, -75.18406], [-12.0468, -75.18406], [-12.04652, -75.18398], [-12.04616, -75.18402], [-12.04376, -75.18546], [-12.0435, -75.18604], [-12.04318, -75.18652], [-12.04234, -75.18724], [-12.04262, -75.18776], [-12.04378, -75.18884], [-12.0439, -75.18908], [-12.0439, -75.18928], [-12.04374, -75.18956], [-12.04374, -75.18984], [-12.04402, -75.1918], [-12.04402, -75.19264], [-12.04434, -75.19392], [-12.04464, -75.19414], [-12.04824, -75.19518], [-12.0486, -75.19518], [-12.0487, -75.19484], [-12.04874, -75.19372], [-12.04838, -75.19124], [-12.04852, -75.1911], [-12.04864, -75.1911], [-12.05068, -75.19206], [-12.0509, -75.19204], [-12.0509, -75.19144]]');


--
-- Data for Name: codigos_barrio; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.codigos_barrio VALUES ('c_b1', 'b1', 'TORRE-2026', true, NULL);
INSERT INTO public.codigos_barrio VALUES ('c_b2', 'b2', 'PALIAN-2026', true, NULL);
INSERT INTO public.codigos_barrio VALUES ('c_b3', 'b3', 'SANCARLOS-2026', true, NULL);
INSERT INTO public.codigos_barrio VALUES ('c_b4', 'b4', 'MONUMENTAL-2026', true, NULL);
INSERT INTO public.codigos_barrio VALUES ('c_b5', 'b5', 'OCOPILLA-2026', true, NULL);
INSERT INTO public.codigos_barrio VALUES ('c_b6', 'b6', 'CAJASCHICO-2026', true, NULL);
INSERT INTO public.codigos_barrio VALUES ('c_b7', 'b7', 'SANANTONIO-2026', true, NULL);
INSERT INTO public.codigos_barrio VALUES ('c_b8', 'b8', 'UNAS-2026', true, NULL);
INSERT INTO public.codigos_barrio VALUES ('c_b9', 'b9', 'CHORRILLOS-2026', true, NULL);


--
-- Data for Name: denuncias_reporte; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: iniciativa_participantes; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.iniciativa_participantes VALUES ('i1', 'v1', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i1', 'v2', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i1', 'v3', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i1', 'v4', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i1', 'v5', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i1', 'v6', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i1', 'v7', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i1', 'v8', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i1', 'v9', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i1', 'v10', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i1', 'v11', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i1', 'v12', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i1', 'v13', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i1', 'v14', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v1', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v2', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v3', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v4', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v5', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v6', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v7', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v8', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v9', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v10', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v11', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v12', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v13', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v14', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v15', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v16', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v17', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v18', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v19', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v20', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v21', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v22', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v23', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v24', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v25', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v26', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v27', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v28', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v29', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v30', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v31', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v32', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v33', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v34', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v35', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v36', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v37', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v38', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v39', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i2', 'v40', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i3', 'v1', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i3', 'v2', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i3', 'v3', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i3', 'v4', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i3', 'v5', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v1', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v2', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v3', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v4', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v5', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v6', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v7', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v8', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v9', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v10', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v11', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v12', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v13', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v14', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v15', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v16', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v17', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v18', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v19', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v20', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v21', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v22', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v23', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v24', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v25', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v26', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v27', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v28', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v29', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i4', 'v30', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i5', 'v1', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i5', 'v2', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i5', 'v3', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i5', 'v4', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i5', 'v5', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i5', 'v6', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i5', 'v7', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i5', 'v8', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i6', 'v1', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i6', 'v2', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i6', 'v3', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i6', 'v4', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i6', 'v5', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i6', 'v6', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i6', 'v7', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i6', 'v8', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i6', 'v9', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i6', 'v10', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i6', 'v11', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i6', 'v12', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i6', 'v13', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i6', 'v14', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i6', 'v15', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i6', 'v16', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i6', 'v17', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i6', 'v18', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i6', 'v19', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i6', 'v20', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i6', 'v21', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i6', 'v22', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i6', 'v23', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i6', 'v24', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i6', 'v25', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i6', 'v26', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i6', 'v27', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i7', 'v1', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i7', 'v2', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i7', 'v3', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i7', 'v4', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i7', 'v5', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i7', 'v6', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i7', 'v7', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i7', 'v8', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i7', 'v9', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i7', 'v10', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i7', 'v11', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i7', 'v12', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v1', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v2', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v3', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v4', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v5', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v6', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v7', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v8', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v9', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v10', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v11', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v12', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v13', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v14', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v15', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v16', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v17', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v18', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v19', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v20', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v21', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v22', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v23', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v24', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v25', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v26', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v27', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v28', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v29', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v30', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v31', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v32', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v33', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v34', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v35', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v36', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v37', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v38', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v39', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i8', 'v40', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i9', 'v1', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i9', 'v2', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i9', 'v3', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i9', 'v4', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i9', 'v5', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i9', 'v6', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i9', 'v7', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i9', 'v8', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i9', 'v9', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i10', 'v1', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i10', 'v2', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i10', 'v3', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i10', 'v4', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i10', 'v5', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i10', 'v6', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i10', 'v7', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i10', 'v8', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i10', 'v9', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i10', 'v10', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i10', 'v11', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i10', 'v12', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i10', 'v13', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i10', 'v14', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i10', 'v15', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i10', 'v16', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i10', 'v17', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i10', 'v18', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i10', 'v19', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i10', 'v20', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i10', 'v21', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i10', 'v22', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i10', 'v23', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i11', 'v1', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i11', 'v2', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i11', 'v3', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i11', 'v4', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i11', 'v5', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i11', 'v6', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i11', 'v7', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v1', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v2', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v3', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v4', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v5', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v6', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v7', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v8', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v9', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v10', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v11', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v12', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v13', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v14', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v15', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v16', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v17', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v18', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v19', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v20', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v21', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v22', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v23', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v24', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v25', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v26', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v27', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v28', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v29', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v30', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v31', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v32', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v33', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v34', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v35', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v36', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v37', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v38', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v39', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i12', 'v40', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v1', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v2', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v3', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v4', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v5', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v6', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v7', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v8', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v9', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v10', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v11', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v12', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v13', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v14', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v15', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v16', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v17', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v18', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v19', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v20', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v21', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v22', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v23', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v24', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v25', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v26', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v27', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v28', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v29', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v30', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v31', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v32', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v33', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v34', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i13', 'v35', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v1', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v2', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v3', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v4', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v5', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v6', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v7', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v8', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v9', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v10', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v11', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v12', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v13', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v14', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v15', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v16', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v17', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v18', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v19', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v20', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v21', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v22', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v23', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v24', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v25', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v26', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v27', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v28', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v29', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v30', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v31', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v32', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v33', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v34', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v35', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v36', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v37', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v38', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v39', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i14', 'v40', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i15', 'v1', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i15', 'v2', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i15', 'v3', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i15', 'v4', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i15', 'v5', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i15', 'v6', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i15', 'v7', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i15', 'v8', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i15', 'v9', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i15', 'v10', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i15', 'v11', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i15', 'v12', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i15', 'v13', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i15', 'v14', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i15', 'v15', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i15', 'v16', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i15', 'v17', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i15', 'v18', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v1', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v2', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v3', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v4', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v5', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v6', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v7', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v8', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v9', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v10', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v11', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v12', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v13', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v14', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v15', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v16', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v17', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v18', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v19', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v20', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v21', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v22', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v23', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v24', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v25', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v26', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v27', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v28', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v29', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v30', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v31', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v32', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v33', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v34', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v35', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v36', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v37', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v38', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v39', '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativa_participantes VALUES ('i16', 'v40', '2026-11-24 01:45:40.600418+00');


--
-- Data for Name: iniciativas; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.iniciativas VALUES ('i1', 'b1', 'v1', 'Ronda vecinal nocturna', 'Turnos de vigilancia los fines de semana.', '20 vecinos inscritos', 'En curso', NULL, '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativas VALUES ('i2', 'b2', 'v2', 'Pedido de alumbrado', 'Solicitud formal de reparación de postes.', '100 firmas', 'Cumplida', 6.2, '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativas VALUES ('i3', 'b3', 'v3', 'Alarma comunitaria', 'Instalar alarma con botón en 10 casas.', 'S/ 1500 recaudados', 'Propuesta', NULL, '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativas VALUES ('i4', 'b2', 'v7', 'Recuperación del parque', 'Limpieza y actividades deportivas.', '3 jornadas', 'En curso', NULL, '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativas VALUES ('i5', 'b1', 'v6', 'Cámaras vecinales', 'Propuesta descartada por presupuesto.', '4 cámaras', 'Cancelada', NULL, '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativas VALUES ('i7', 'b6', 'v18', 'Vecinos en alerta', 'Red de mensajes para avisos inmediatos.', '60 vecinos', 'Propuesta', NULL, '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativas VALUES ('i8', 'b7', 'v21', 'Cancha segura', 'Recuperar la losa deportiva y cerrarla de noche.', '1 losa', 'En curso', NULL, '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativas VALUES ('i9', 'b8', 'v24', 'Botones de pánico', 'Instalar botones en las esquinas con más robos.', '6 botones', 'Propuesta', NULL, '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativas VALUES ('i10', 'b9', 'v27', 'Huertos comunitarios', 'Convertir un terreno baldío en huerto vecinal.', '1 terreno', 'En curso', NULL, '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativas VALUES ('i11', 'b6', 'v30', 'Muro y luces', 'Cerrar el pasaje oscuro y colocar reflectores.', '80 metros', 'Propuesta', NULL, '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativas VALUES ('i12', 'b7', 'v33', 'Campaña de valores', 'Talleres de convivencia para jóvenes.', '4 talleres', 'Cumplida', 12.8, '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativas VALUES ('i13', 'b9', 'v36', 'Jornada de limpieza', 'Retirar basura acumulada en la quebrada.', '2 jornadas', 'En curso', NULL, '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativas VALUES ('i14', 'b5', 'v15', 'Feria de seguridad', 'Feria informativa con Serenazgo y Policía.', '1 feria', 'Cumplida', 8.1, '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativas VALUES ('i15', 'b3', 'v9', 'Veredas iluminadas', 'Mejorar veredas y alumbrado del ingreso.', '300 metros', 'Propuesta', NULL, '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativas VALUES ('i16', 'b1', 'v3', 'Directorio de emergencia', 'Directorio de contactos útiles por manzana.', '1 directorio', 'Cumplida', 4.4, '2026-11-24 01:45:40.600418+00');
INSERT INTO public.iniciativas VALUES ('i6', 'b4', 'v10', 'Luz para Zona Monumental', 'Cambio de luminarias en las calles altas.', '15 postes', 'En curso', NULL, '2026-11-24 01:45:40.600418+00');


--
-- Data for Name: noticias_leidas; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.noticias_leidas VALUES ('v1', 'a2', '2026-11-24 21:16:25.406758+00');
INSERT INTO public.noticias_leidas VALUES ('v1', 'a14', '2026-11-24 21:16:25.406758+00');
INSERT INTO public.noticias_leidas VALUES ('v1', 'a1', '2026-11-24 21:16:25.406758+00');


--
-- Data for Name: reportes; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.reportes VALUES ('r1', 'v1', 'b1', -12.055915, -75.188339, 'asalto_robo', 5, 'Robo al paso a mano armada a transeúnte en Avenida Alameda', '2026-11-22 13:00:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r2', 'v10', 'b1', -12.04994, -75.186711, 'falta_alumbrado', 2, 'Tramo sin iluminación pública por luminarias quemadas en Los Manzanos', '2026-11-09 07:43:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r3', 'v19', 'b1', -12.059898, -75.18412, 'otro', 1, 'Ruidos molestos y escándalo vecinal hasta altas horas de la madrugada en Avenida Via Integracion Este', '2026-11-10 02:26:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r4', 'v28', 'b1', -12.051155, -75.191902, 'pandillaje', 3, 'Pintas vandálicas y escándalo en Pasaje Las Tunas', '2026-11-10 21:09:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r5', 'v1', 'b1', -12.054641, -75.183841, 'actividad_sospechosa', 1, 'Vehículo estacionado con individuos observando viviendas sospechosamente en Jirón Quishuar', '2026-11-11 16:52:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r6', 'v10', 'b1', -12.059327, -75.187983, 'asalto_robo', 5, 'Arrebato de celular y pertenencias por sujetos en moto en Avenida Circunvalacion', '2026-11-13 11:35:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r7', 'v19', 'b1', -12.052705, -75.189063, 'alcohol_drogas', 3, 'Consumo de drogas y botellas rotas frente a viviendas en Jirón Fénix', '2026-11-14 06:18:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r8', 'v28', 'b1', -12.05305, -75.18623, 'asalto_robo', 5, 'Robo con arma blanca a joven que retornaba a su domicilio en Capitán Gutierrez Espinoza', '2026-11-15 01:01:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r9', 'v1', 'b1', -12.057238, -75.185863, 'falta_alumbrado', 2, 'Poste de alumbrado público inoperativo, dejando la cuadra a oscuras en Pasaje Naranjillo', '2026-11-15 20:44:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r10', 'v2', 'b2', -12.041659, -75.19009, 'asalto_robo', 5, 'Arrebato de celular y pertenencias por sujetos en moto en Avenida Universitaria', '2026-11-14 10:00:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r11', 'v11', 'b2', -12.03245, -75.196004, 'alcohol_drogas', 3, 'Consumo de drogas y botellas rotas frente a viviendas en Jirón Santa Rosa', '2026-11-01 04:43:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r12', 'v20', 'b2', -12.041898, -75.198319, 'asalto_robo', 5, 'Robo con arma blanca a joven que retornaba a su domicilio en Calle José Santos Chocano', '2026-11-11 23:26:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r13', 'v29', 'b2', -12.034384, -75.190279, 'falta_alumbrado', 2, 'Poste de alumbrado público inoperativo, dejando la cuadra a oscuras en Avenida Palián', '2026-10-29 18:09:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r14', 'v2', 'b2', -12.038004, -75.194621, 'otro', 1, 'Jauría de canes agresivos sin correa en plena vía pública de Psje. Colón (Palián)', '2026-11-09 13:52:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r15', 'v11', 'b2', -12.04382, -75.193888, 'pandillaje', 3, 'Disturbios y peleas al anochecer en la esquina de Jirón Venus', '2026-11-21 08:35:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r16', 'v20', 'b2', -12.038415, -75.187709, 'actividad_sospechosa', 1, 'Sujetos vigilando movimientos de vecinos en Avenida Alameda Universitaria', '2026-11-08 03:18:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r17', 'v29', 'b2', -12.037225, -75.198148, 'asalto_robo', 5, 'Robo al paso a mano armada a transeúnte en Calle Libra', '2026-11-18 22:01:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r18', 'v2', 'b2', -12.037867, -75.191197, 'alcohol_drogas', 3, 'Personas bebiendo licor en la acera y bloqueando el paso en Jirón Los Álamos', '2026-11-05 17:44:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r19', 'v11', 'b2', -12.03257, -75.193029, 'asalto_robo', 5, 'Asalto a una vecina cerca del paradero en Calle José Olaya', '2026-11-17 12:27:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r20', 'v20', 'b2', -12.040707, -75.192891, 'falta_alumbrado', 2, 'Falta total de alumbrado en pasaje peatonal de Calle El Sol', '2026-11-04 07:10:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r21', 'v3', 'b3', -12.060295, -75.210387, 'pandillaje', 3, 'Disturbios y peleas al anochecer en la esquina de Avenida Ferrocarril', '2026-11-20 07:00:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r22', 'v12', 'b3', -12.057395, -75.196494, 'actividad_sospechosa', 1, 'Sujetos vigilando movimientos de vecinos en Jirón Maypu', '2026-11-18 01:43:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r23', 'v21', 'b3', -12.070296, -75.201612, 'asalto_robo', 5, 'Robo al paso a mano armada a transeúnte en Prolongación Huanuco', '2026-11-15 20:26:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r24', 'v30', 'b3', -12.051608, -75.20472, 'alcohol_drogas', 3, 'Personas bebiendo licor en la acera y bloqueando el paso en Calle San Antonio', '2026-11-13 15:09:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r25', 'v3', 'b3', -12.062499, -75.202551, 'asalto_robo', 5, 'Asalto a una vecina cerca del paradero en Pasaje San Antonio', '2026-11-23 10:52:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r26', 'v12', 'b3', -12.057383, -75.205221, 'falta_alumbrado', 2, 'Falta total de alumbrado en pasaje peatonal de Jirón Brasilia', '2026-11-21 05:35:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r27', 'v21', 'b3', -12.066542, -75.206373, 'otro', 1, 'Acumulación clandestina de desmonte y basura obstaculizando el tránsito en Avenida Giraldez', '2026-11-19 00:18:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r28', 'v30', 'b3', -12.054749, -75.200895, 'pandillaje', 3, 'Enfrentamiento entre grupos callejeros con piedras en Pasaje Santa Isabel', '2026-11-16 19:01:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r29', 'v3', 'b3', -12.065985, -75.199168, 'actividad_sospechosa', 1, 'Desconocidos merodeando de madrugada y observando entradas en Pasaje Santa Fe', '2026-11-14 14:44:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r30', 'v12', 'b3', -12.058942, -75.200392, 'asalto_robo', 5, 'Robo con arma blanca a joven que retornaba a su domicilio en Pasaje Gerónimo da Silva', '2026-11-13 09:27:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r31', 'v21', 'b3', -12.062481, -75.20695, 'alcohol_drogas', 3, 'Sujetos consumiendo bebidas alcohólicas y sustancias en la vía pública de Jirón Abancay', '2026-11-22 04:10:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r32', 'v30', 'b3', -12.065702, -75.202747, 'asalto_robo', 5, 'Arrebato de celular y pertenencias por sujetos en moto en Jirón San Francisco de Asis', '2026-11-19 23:53:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r33', 'v3', 'b3', -12.061868, -75.19954, 'falta_alumbrado', 2, 'Luminaria intermitente y zona muy oscura en horas de la noche en Avenida José Olaya', '2026-11-17 18:36:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r34', 'v12', 'b3', -12.069145, -75.204887, 'otro', 1, 'Buzón de desagüe sin tapa representando peligro peatonal en Jirón Atahualpa', '2026-11-15 13:19:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r35', 'v4', 'b4', -12.06631, -75.211672, 'falta_alumbrado', 2, 'Falta total de alumbrado en pasaje peatonal de Calle Real', '2026-11-18 04:00:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r36', 'v13', 'b4', -12.072927, -75.203168, 'otro', 1, 'Acumulación clandestina de desmonte y basura obstaculizando el tránsito en Avenida Jacinto Ibarra', '2026-11-20 22:43:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r37', 'v22', 'b4', -12.075655, -75.213699, 'pandillaje', 3, 'Enfrentamiento entre grupos callejeros con piedras en Cajamarca', '2026-11-15 17:26:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r38', 'v31', 'b4', -12.072255, -75.209231, 'actividad_sospechosa', 1, 'Desconocidos merodeando de madrugada y observando entradas en Jirón Arequipa', '2026-11-19 12:09:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r39', 'v4', 'b4', -12.067529, -75.206311, 'asalto_robo', 5, 'Robo con arma blanca a joven que retornaba a su domicilio en Jirón Pachitea', '2026-11-22 07:52:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r40', 'v13', 'b4', -12.070319, -75.215244, 'alcohol_drogas', 3, 'Sujetos consumiendo bebidas alcohólicas y sustancias en la vía pública de Pasaje Morales', '2026-11-17 02:35:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r41', 'v22', 'b4', -12.063799, -75.208726, 'asalto_robo', 5, 'Arrebato de celular y pertenencias por sujetos en moto en Pasaje Culis', '2026-11-19 21:18:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r42', 'v31', 'b4', -12.074966, -75.206397, 'falta_alumbrado', 2, 'Luminaria intermitente y zona muy oscura en horas de la noche en Jirón Angaraez', '2026-11-22 16:01:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r43', 'v4', 'b4', -12.075921, -75.21023, 'otro', 1, 'Buzón de desagüe sin tapa representando peligro peatonal en Jirón Tarapaca', '2026-11-18 11:44:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r44', 'v13', 'b4', -12.069578, -75.211938, 'pandillaje', 3, 'Grupo de jóvenes generando disturbios y amedrentando peatones en Avenida Paseo de la Breña', '2026-11-21 06:27:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r45', 'v22', 'b4', -12.069717, -75.203638, 'actividad_sospechosa', 1, 'Persona encapuchada intentando forzar portones de garaje en Jirón Piura Antigua', '2026-11-16 01:10:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r46', 'v31', 'b4', -12.071563, -75.206033, 'asalto_robo', 5, 'Asalto a una vecina cerca del paradero en Jirón Mantaro', '2026-11-18 20:53:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r47', 'v4', 'b4', -12.068967, -75.208963, 'alcohol_drogas', 3, 'Grupo libando y generando desorden vecinal en Jirón Ancash', '2026-11-21 15:36:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r48', 'v13', 'b4', -12.072774, -75.212156, 'asalto_robo', 5, 'Robo al paso a mano armada a transeúnte en Jirón Ica', '2026-11-17 10:19:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r49', 'v22', 'b4', -12.067986, -75.214523, 'falta_alumbrado', 2, 'Tramo sin iluminación pública por luminarias quemadas en Jirón Ayacucho', '2026-11-20 05:02:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r50', 'v5', 'b5', -12.073061, -75.198978, 'alcohol_drogas', 3, 'Sujetos consumiendo bebidas alcohólicas y sustancias en la vía pública de Avenida Ocopilla', '2026-11-12 01:00:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r51', 'v14', 'b5', -12.062626, -75.181393, 'asalto_robo', 5, 'Arrebato de celular y pertenencias por sujetos en moto en Avenida Taylor', '2026-11-16 19:43:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r52', 'v23', 'b5', -12.057706, -75.196227, 'falta_alumbrado', 2, 'Luminaria intermitente y zona muy oscura en horas de la noche en Jirón Maypu', '2026-11-21 14:26:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r53', 'v32', 'b5', -12.069052, -75.18947, 'otro', 1, 'Buzón de desagüe sin tapa representando peligro peatonal en Jirón Andres Avelino Caceres', '2026-11-09 09:09:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r54', 'v5', 'b5', -12.059025, -75.188517, 'pandillaje', 3, 'Grupo de jóvenes generando disturbios y amedrentando peatones en Calle 14 de Junio', '2026-11-14 04:52:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r55', 'v14', 'b5', -12.065662, -75.196499, 'actividad_sospechosa', 1, 'Persona encapuchada intentando forzar portones de garaje en Circunvalacion', '2026-11-18 23:35:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r56', 'v23', 'b5', -12.074003, -75.192786, 'asalto_robo', 5, 'Asalto a una vecina cerca del paradero en Avenida Leoncio Prado', '2026-11-05 18:18:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r57', 'v32', 'b5', -12.063615, -75.191285, 'alcohol_drogas', 3, 'Grupo libando y generando desorden vecinal en Pasaje San Valentin', '2026-11-10 13:01:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r58', 'v5', 'b5', -12.064389, -75.185924, 'asalto_robo', 5, 'Robo al paso a mano armada a transeúnte en Jirón Piura Antigua', '2026-11-16 08:44:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r59', 'v14', 'b5', -12.077585, -75.200404, 'falta_alumbrado', 2, 'Tramo sin iluminación pública por luminarias quemadas en Avenida Jacinto Ibarra', '2026-11-21 03:27:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r60', 'v23', 'b5', -12.069983, -75.195425, 'otro', 1, 'Ruidos molestos y escándalo vecinal hasta altas horas de la madrugada en Jirón Inclán', '2026-11-07 22:10:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r61', 'v32', 'b5', -12.056377, -75.192136, 'pandillaje', 3, 'Pintas vandálicas y escándalo en Jirón Chacabuco', '2026-11-12 17:53:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r62', 'v6', 'b6', -12.072985, -75.216375, 'actividad_sospechosa', 1, 'Persona encapuchada intentando forzar portones de garaje en Jirón Lima', '2026-11-12 22:00:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r63', 'v15', 'b6', -12.081178, -75.22793, 'asalto_robo', 5, 'Asalto a una vecina cerca del paradero en Jirón Ica Nueva', '2026-10-30 16:43:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r64', 'v24', 'b6', -12.075406, -75.223347, 'alcohol_drogas', 3, 'Grupo libando y generando desorden vecinal en Pasaje 14 de Julio', '2026-11-15 11:26:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r65', 'v33', 'b6', -12.079184, -75.218247, 'asalto_robo', 5, 'Robo al paso a mano armada a transeúnte en Jirón Tarapaca', '2026-11-02 06:09:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r66', 'v6', 'b6', -12.080407, -75.22267, 'falta_alumbrado', 2, 'Tramo sin iluminación pública por luminarias quemadas en Jirón Las Retamas', '2026-11-17 01:52:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r67', 'v15', 'b6', -12.077256, -75.22689, 'otro', 1, 'Ruidos molestos y escándalo vecinal hasta altas horas de la madrugada en Pasaje Uno', '2026-11-03 20:35:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r68', 'v24', 'b6', -12.073022, -75.220162, 'pandillaje', 3, 'Pintas vandálicas y escándalo en Pasaje 5 de Octubre', '2026-11-18 15:18:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r69', 'v33', 'b6', -12.076663, -75.215524, 'actividad_sospechosa', 1, 'Vehículo estacionado con individuos observando viviendas sospechosamente en Cajamarca', '2026-11-06 10:01:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r70', 'v6', 'b6', -12.077425, -75.220835, 'asalto_robo', 5, 'Arrebato de celular y pertenencias por sujetos en moto en Pasaje Los Rosales', '2026-10-24 05:44:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r71', 'v15', 'b6', -12.079909, -75.225492, 'alcohol_drogas', 3, 'Consumo de drogas y botellas rotas frente a viviendas en Pasaje Carrión', '2026-11-08 00:27:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r72', 'v7', 'b7', -12.052907, -75.199641, 'otro', 1, 'Ruidos molestos y escándalo vecinal hasta altas horas de la madrugada en Avenida Mártires del Periodismo', '2026-11-15 19:00:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r73', 'v16', 'b7', -12.043215, -75.196357, 'pandillaje', 3, 'Pintas vandálicas y escándalo en Pasaje San Luis', '2026-11-14 13:43:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r74', 'v25', 'b7', -12.055833, -75.191405, 'actividad_sospechosa', 1, 'Vehículo estacionado con individuos observando viviendas sospechosamente en Jirón Chacabuco', '2026-11-14 08:26:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r75', 'v34', 'b7', -12.048658, -75.191801, 'asalto_robo', 5, 'Arrebato de celular y pertenencias por sujetos en moto en Calle Los Alamos', '2026-11-13 03:09:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r76', 'v7', 'b7', -12.047425, -75.200389, 'alcohol_drogas', 3, 'Consumo de drogas y botellas rotas frente a viviendas en Jirón San Pablo Miki', '2026-11-11 22:52:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r77', 'v16', 'b7', -12.051306, -75.204485, 'asalto_robo', 5, 'Robo con arma blanca a joven que retornaba a su domicilio en Jirón San Santiago', '2026-11-10 17:35:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r78', 'v25', 'b7', -12.056369, -75.196224, 'falta_alumbrado', 2, 'Poste de alumbrado público inoperativo, dejando la cuadra a oscuras en Calle C', '2026-11-22 12:18:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r79', 'v34', 'b7', -12.05185, -75.195133, 'otro', 1, 'Jauría de canes agresivos sin correa en plena vía pública de Avenida José Olaya', '2026-11-21 07:01:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r80', 'v7', 'b7', -12.047458, -75.196106, 'pandillaje', 3, 'Disturbios y peleas al anochecer en la esquina de Pasaje Samuel', '2026-11-20 02:44:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r81', 'v16', 'b7', -12.049927, -75.198104, 'actividad_sospechosa', 1, 'Sujetos vigilando movimientos de vecinos en Jirón San Agustín', '2026-11-18 21:27:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r82', 'v25', 'b7', -12.050351, -75.201627, 'asalto_robo', 5, 'Robo al paso a mano armada a transeúnte en Pasaje Progreso', '2026-11-17 16:10:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r83', 'v34', 'b7', -12.045454, -75.19831, 'alcohol_drogas', 3, 'Personas bebiendo licor en la acera y bloqueando el paso en Jirón Santa María Goretti', '2026-11-17 11:53:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r84', 'v7', 'b7', -12.04522, -75.194339, 'asalto_robo', 5, 'Asalto a una vecina cerca del paradero en Pasaje Santa Cecilia', '2026-11-16 06:36:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r85', 'v8', 'b8', -12.028523, -75.18622, 'asalto_robo', 5, 'Robo con arma blanca a joven que retornaba a su domicilio en Calle Progreso', '2026-11-09 16:00:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r86', 'v17', 'b8', -12.028083, -75.196722, 'falta_alumbrado', 2, 'Poste de alumbrado público inoperativo, dejando la cuadra a oscuras en Jirón El Sol', '2026-11-16 10:43:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r87', 'v26', 'b8', -12.036352, -75.189437, 'otro', 1, 'Jauría de canes agresivos sin correa en plena vía pública de Pasaje Las Flores', '2026-11-03 05:26:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r88', 'v35', 'b8', -12.02296, -75.190959, 'pandillaje', 3, 'Disturbios y peleas al anochecer en la esquina de San Luis', '2026-11-09 00:09:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r89', 'v8', 'b8', -12.031751, -75.192273, 'actividad_sospechosa', 1, 'Sujetos vigilando movimientos de vecinos en Calle José de San Martín', '2026-11-14 19:52:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r90', 'v17', 'b8', -12.025132, -75.182535, 'asalto_robo', 5, 'Robo al paso a mano armada a transeúnte en Avenida El Sol', '2026-11-20 14:35:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r91', 'v26', 'b8', -12.027243, -75.1918, 'alcohol_drogas', 3, 'Personas bebiendo licor en la acera y bloqueando el paso en Avenida Agricultura', '2026-11-08 09:18:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r92', 'v35', 'b8', -12.024585, -75.186515, 'asalto_robo', 5, 'Asalto a una vecina cerca del paradero en Calle 2', '2026-11-14 04:01:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r93', 'v8', 'b8', -12.031215, -75.188639, 'falta_alumbrado', 2, 'Falta total de alumbrado en pasaje peatonal de Jirón Los Álamos', '2026-11-19 23:44:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r94', 'v17', 'b8', -12.026656, -75.188721, 'otro', 1, 'Acumulación clandestina de desmonte y basura obstaculizando el tránsito en Calle Cantuta', '2026-11-06 18:27:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r95', 'v26', 'b8', -12.027673, -75.183543, 'pandillaje', 3, 'Enfrentamiento entre grupos callejeros con piedras en JIrón San Felipe', '2026-11-12 13:10:00+00', 'confirmado');
INSERT INTO public.reportes VALUES ('r96', 'v9', 'b9', -12.048414, -75.187325, 'asalto_robo', 5, 'Robo al paso a mano armada a transeúnte en Los Robles', '2026-10-26 13:00:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r97', 'v18', 'b9', -12.048615, -75.194901, 'alcohol_drogas', 3, 'Personas bebiendo licor en la acera y bloqueando el paso en Calle Las Orquideas', '2026-11-14 07:43:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r98', 'v27', 'b9', -12.044275, -75.191176, 'asalto_robo', 5, 'Asalto a una vecina cerca del paradero en Jirón Los Andes', '2026-11-01 02:26:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r99', 'v36', 'b9', -12.050504, -75.191092, 'falta_alumbrado', 2, 'Falta total de alumbrado en pasaje peatonal de Los Fresnos', '2026-10-18 21:09:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r100', 'v9', 'b9', -12.045168, -75.187338, 'otro', 1, 'Acumulación clandestina de desmonte y basura obstaculizando el tránsito en Jirón Jhantu', '2026-11-06 16:52:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r101', 'v18', 'b9', -12.047378, -75.191496, 'pandillaje', 3, 'Enfrentamiento entre grupos callejeros con piedras en Calle El Paraiso', '2026-10-25 11:35:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r102', 'v27', 'b9', -12.047961, -75.189447, 'actividad_sospechosa', 1, 'Desconocidos merodeando de madrugada y observando entradas en Jirón Centauro', '2026-11-13 06:18:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r103', 'v36', 'b9', -12.04977, -75.188761, 'asalto_robo', 5, 'Robo con arma blanca a joven que retornaba a su domicilio en Calle Alameda La Merced Sur', '2026-10-31 01:01:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r104', 'v9', 'b9', -12.045714, -75.190043, 'alcohol_drogas', 3, 'Sujetos consumiendo bebidas alcohólicas y sustancias en la vía pública de Avenida Las Flores', '2026-11-18 20:44:00+00', 'activo');
INSERT INTO public.reportes VALUES ('r105', 'v18', 'b9', -12.047335, -75.1933, 'asalto_robo', 5, 'Arrebato de celular y pertenencias por sujetos en moto en Calle Las Margaritas', '2026-11-05 15:27:00+00', 'activo');


--
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.usuarios VALUES ('v1', 'Rosa Quispe', '40000001', 'vecino@barrio.com', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b1', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v2', 'Juan Huamán', '40000002', 'vecino2@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b2', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v3', 'María Rojas', '40000003', 'vecino3@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b3', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v4', 'Carlos Poma', '40000004', 'vecino4@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b4', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v5', 'Lucía Ccanto', '40000005', 'vecino5@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b5', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v6', 'Pedro Mendoza', '40000006', 'vecino6@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b6', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v7', 'Ana Taipe', '40000007', 'vecino7@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b7', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v8', 'Luis Cárdenas', '40000008', 'vecino8@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b8', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v9', 'Elena Soto', '40000009', 'vecino9@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b9', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v10', 'Jorge Inga', '40000010', 'vecino10@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b1', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v11', 'Carmen Ríos', '40000011', 'vecino11@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b2', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v12', 'Raúl Chávez', '40000012', 'vecino12@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b3', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v13', 'Sofía Yupanqui', '40000013', 'vecino13@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b4', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v14', 'Diego Ramos', '40000014', 'vecino14@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b5', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v15', 'Patricia Vila', '40000015', 'vecino15@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b6', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v16', 'Julio Ccahuana', '40000016', 'vecino16@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b7', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v17', 'Marisol Laura', '40000017', 'vecino17@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b8', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v18', 'Percy Quispe', '40000018', 'vecino18@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b9', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v19', 'Yolanda Canchanya', '40000019', 'vecino19@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b1', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v20', 'Fredy Baldeón', '40000020', 'vecino20@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b2', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v21', 'Norma Pariona', '40000021', 'vecino21@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b3', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v22', 'Alfredo Yupanqui', '40000022', 'vecino22@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b4', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v23', 'Karina Camarena', '40000023', 'vecino23@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b5', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v24', 'Rubén Sulca', '40000024', 'vecino24@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b6', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v25', 'Betty Paucar', '40000025', 'vecino25@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b7', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v26', 'Héctor Contreras', '40000026', 'vecino26@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b8', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v27', 'Milagros Rojas', '40000027', 'vecino27@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b9', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v28', 'Óscar Espinoza', '40000028', 'vecino28@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b1', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v29', 'Diana Aylas', '40000029', 'vecino29@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b2', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v30', 'Wilmer Torres', '40000030', 'vecino30@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b3', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v31', 'Gladys Chuquillanqui', '40000031', 'vecino31@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b4', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v32', 'César Santos', '40000032', 'vecino32@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b5', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v33', 'Verónica Landa', '40000033', 'vecino33@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b6', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v34', 'Abelardo Ñahui', '40000034', 'vecino34@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b7', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v35', 'Roxana Cisneros', '40000035', 'vecino35@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b8', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v36', 'Teodoro Mucha', '40000036', 'vecino36@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b9', 'Verificado', 0, NULL, NULL, '2026-09-25 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v37', 'Miguel Arias', '40000037', 'pendiente1@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b4', 'Pendiente', 0, NULL, NULL, '2026-11-23 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v38', 'Gloria Palacios', '40000038', 'pendiente2@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b7', 'Pendiente', 0, NULL, NULL, '2026-11-22 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v39', 'Hugo Salazar', '40000039', 'pendiente3@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b6', 'Pendiente', 0, NULL, NULL, '2026-11-21 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('v40', 'Rita Campos', '40000040', 'pendiente4@radar.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'vecino', 'b2', 'Pendiente', 0, NULL, NULL, '2026-11-20 01:45:40.596354+00', NULL);
INSERT INTO public.usuarios VALUES ('m1', 'Gerencia de Seguridad Ciudadana', '00000001', 'muni@huancayo.gob.pe', '$argon2id$v=19$m=65536,t=3,p=4$2UrUV+nhavxkX010Bb53og$Kcis+5em1d9q2jgWPmklShD5wVJW7+6HH/v0PwZxVMY', 'municipalidad', NULL, 'Verificado', 0, NULL, NULL, '2026-08-26 01:45:40.596354+00', 'Municipalidad');


--
-- Data for Name: votos_reporte; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.votos_reporte VALUES ('r2', 'v2', 'confirmo', '2026-11-09 08:58:00+00');
INSERT INTO public.votos_reporte VALUES ('r2', 'v3', 'confirmo', '2026-11-09 09:58:00+00');
INSERT INTO public.votos_reporte VALUES ('r4', 'v4', 'confirmo', '2026-11-10 22:24:00+00');
INSERT INTO public.votos_reporte VALUES ('r4', 'v5', 'confirmo', '2026-11-10 23:24:00+00');
INSERT INTO public.votos_reporte VALUES ('r6', 'v6', 'confirmo', '2026-11-13 12:50:00+00');
INSERT INTO public.votos_reporte VALUES ('r6', 'v7', 'confirmo', '2026-11-13 13:50:00+00');
INSERT INTO public.votos_reporte VALUES ('r8', 'v8', 'confirmo', '2026-11-15 02:16:00+00');
INSERT INTO public.votos_reporte VALUES ('r8', 'v9', 'confirmo', '2026-11-15 03:16:00+00');
INSERT INTO public.votos_reporte VALUES ('r10', 'v6', 'confirmo', '2026-11-14 11:15:00+00');
INSERT INTO public.votos_reporte VALUES ('r11', 'v6', 'confirmo', '2026-11-01 05:58:00+00');
INSERT INTO public.votos_reporte VALUES ('r11', 'v7', 'confirmo', '2026-11-01 06:58:00+00');
INSERT INTO public.votos_reporte VALUES ('r11', 'v8', 'confirmo', '2026-11-01 07:58:00+00');
INSERT INTO public.votos_reporte VALUES ('r12', 'v7', 'confirmo', '2026-11-12 00:41:00+00');
INSERT INTO public.votos_reporte VALUES ('r13', 'v8', 'confirmo', '2026-10-29 19:24:00+00');
INSERT INTO public.votos_reporte VALUES ('r13', 'v9', 'confirmo', '2026-10-29 20:24:00+00');
INSERT INTO public.votos_reporte VALUES ('r13', 'v10', 'confirmo', '2026-10-29 21:24:00+00');
INSERT INTO public.votos_reporte VALUES ('r14', 'v10', 'confirmo', '2026-11-09 15:07:00+00');
INSERT INTO public.votos_reporte VALUES ('r15', 'v10', 'confirmo', '2026-11-21 09:50:00+00');
INSERT INTO public.votos_reporte VALUES ('r15', 'v12', 'confirmo', '2026-11-21 10:50:00+00');
INSERT INTO public.votos_reporte VALUES ('r15', 'v13', 'confirmo', '2026-11-21 11:50:00+00');
INSERT INTO public.votos_reporte VALUES ('r16', 'v11', 'confirmo', '2026-11-08 04:33:00+00');
INSERT INTO public.votos_reporte VALUES ('r17', 'v12', 'confirmo', '2026-11-18 23:16:00+00');
INSERT INTO public.votos_reporte VALUES ('r17', 'v13', 'confirmo', '2026-11-19 00:16:00+00');
INSERT INTO public.votos_reporte VALUES ('r17', 'v14', 'confirmo', '2026-11-19 01:16:00+00');
INSERT INTO public.votos_reporte VALUES ('r18', 'v14', 'confirmo', '2026-11-05 18:59:00+00');
INSERT INTO public.votos_reporte VALUES ('r19', 'v15', 'confirmo', '2026-11-17 13:42:00+00');
INSERT INTO public.votos_reporte VALUES ('r19', 'v16', 'confirmo', '2026-11-17 14:42:00+00');
INSERT INTO public.votos_reporte VALUES ('r19', 'v17', 'confirmo', '2026-11-17 15:42:00+00');
INSERT INTO public.votos_reporte VALUES ('r20', 'v15', 'confirmo', '2026-11-04 08:25:00+00');
INSERT INTO public.votos_reporte VALUES ('r21', 'v10', 'confirmo', '2026-11-20 08:15:00+00');
INSERT INTO public.votos_reporte VALUES ('r21', 'v11', 'confirmo', '2026-11-20 09:15:00+00');
INSERT INTO public.votos_reporte VALUES ('r21', 'v12', 'confirmo', '2026-11-20 10:15:00+00');
INSERT INTO public.votos_reporte VALUES ('r23', 'v11', 'confirmo', '2026-11-15 21:41:00+00');
INSERT INTO public.votos_reporte VALUES ('r23', 'v12', 'confirmo', '2026-11-15 22:41:00+00');
INSERT INTO public.votos_reporte VALUES ('r24', 'v12', 'confirmo', '2026-11-13 16:24:00+00');
INSERT INTO public.votos_reporte VALUES ('r24', 'v13', 'confirmo', '2026-11-13 17:24:00+00');
INSERT INTO public.votos_reporte VALUES ('r24', 'v14', 'confirmo', '2026-11-13 18:24:00+00');
INSERT INTO public.votos_reporte VALUES ('r25', 'v14', 'confirmo', '2026-11-23 12:07:00+00');
INSERT INTO public.votos_reporte VALUES ('r25', 'v15', 'confirmo', '2026-11-23 13:07:00+00');
INSERT INTO public.votos_reporte VALUES ('r27', 'v15', 'confirmo', '2026-11-19 01:33:00+00');
INSERT INTO public.votos_reporte VALUES ('r27', 'v16', 'confirmo', '2026-11-19 02:33:00+00');
INSERT INTO public.votos_reporte VALUES ('r27', 'v17', 'confirmo', '2026-11-19 03:33:00+00');
INSERT INTO public.votos_reporte VALUES ('r29', 'v18', 'confirmo', '2026-11-14 15:59:00+00');
INSERT INTO public.votos_reporte VALUES ('r29', 'v19', 'confirmo', '2026-11-14 16:59:00+00');
INSERT INTO public.votos_reporte VALUES ('r30', 'v19', 'confirmo', '2026-11-13 10:42:00+00');
INSERT INTO public.votos_reporte VALUES ('r30', 'v20', 'confirmo', '2026-11-13 11:42:00+00');
INSERT INTO public.votos_reporte VALUES ('r30', 'v21', 'confirmo', '2026-11-13 12:42:00+00');
INSERT INTO public.votos_reporte VALUES ('r31', 'v19', 'confirmo', '2026-11-22 05:25:00+00');
INSERT INTO public.votos_reporte VALUES ('r31', 'v20', 'confirmo', '2026-11-22 06:25:00+00');
INSERT INTO public.votos_reporte VALUES ('r33', 'v22', 'confirmo', '2026-11-17 19:51:00+00');
INSERT INTO public.votos_reporte VALUES ('r33', 'v23', 'confirmo', '2026-11-17 20:51:00+00');
INSERT INTO public.votos_reporte VALUES ('r33', 'v24', 'confirmo', '2026-11-17 21:51:00+00');
INSERT INTO public.votos_reporte VALUES ('r35', 'v14', 'confirmo', '2026-11-18 05:15:00+00');
INSERT INTO public.votos_reporte VALUES ('r35', 'v15', 'confirmo', '2026-11-18 06:15:00+00');
INSERT INTO public.votos_reporte VALUES ('r35', 'v16', 'confirmo', '2026-11-18 07:15:00+00');
INSERT INTO public.votos_reporte VALUES ('r36', 'v15', 'confirmo', '2026-11-20 23:58:00+00');
INSERT INTO public.votos_reporte VALUES ('r37', 'v15', 'confirmo', '2026-11-15 18:41:00+00');
INSERT INTO public.votos_reporte VALUES ('r37', 'v16', 'confirmo', '2026-11-15 19:41:00+00');
INSERT INTO public.votos_reporte VALUES ('r37', 'v17', 'confirmo', '2026-11-15 20:41:00+00');
INSERT INTO public.votos_reporte VALUES ('r38', 'v16', 'confirmo', '2026-11-19 13:24:00+00');
INSERT INTO public.votos_reporte VALUES ('r38', 'v17', 'confirmo', '2026-11-19 14:24:00+00');
INSERT INTO public.votos_reporte VALUES ('r38', 'v18', 'confirmo', '2026-11-19 15:24:00+00');
INSERT INTO public.votos_reporte VALUES ('r39', 'v18', 'confirmo', '2026-11-22 09:07:00+00');
INSERT INTO public.votos_reporte VALUES ('r39', 'v19', 'confirmo', '2026-11-22 10:07:00+00');
INSERT INTO public.votos_reporte VALUES ('r39', 'v20', 'confirmo', '2026-11-22 11:07:00+00');
INSERT INTO public.votos_reporte VALUES ('r40', 'v19', 'confirmo', '2026-11-17 03:50:00+00');
INSERT INTO public.votos_reporte VALUES ('r41', 'v19', 'confirmo', '2026-11-19 22:33:00+00');
INSERT INTO public.votos_reporte VALUES ('r41', 'v20', 'confirmo', '2026-11-19 23:33:00+00');
INSERT INTO public.votos_reporte VALUES ('r41', 'v21', 'confirmo', '2026-11-20 00:33:00+00');
INSERT INTO public.votos_reporte VALUES ('r42', 'v20', 'confirmo', '2026-11-22 17:16:00+00');
INSERT INTO public.votos_reporte VALUES ('r43', 'v22', 'confirmo', '2026-11-18 12:59:00+00');
INSERT INTO public.votos_reporte VALUES ('r43', 'v23', 'confirmo', '2026-11-18 13:59:00+00');
INSERT INTO public.votos_reporte VALUES ('r43', 'v24', 'confirmo', '2026-11-18 14:59:00+00');
INSERT INTO public.votos_reporte VALUES ('r44', 'v23', 'confirmo', '2026-11-21 07:42:00+00');
INSERT INTO public.votos_reporte VALUES ('r44', 'v24', 'confirmo', '2026-11-21 08:42:00+00');
INSERT INTO public.votos_reporte VALUES ('r44', 'v25', 'confirmo', '2026-11-21 09:42:00+00');
INSERT INTO public.votos_reporte VALUES ('r45', 'v24', 'confirmo', '2026-11-16 02:25:00+00');
INSERT INTO public.votos_reporte VALUES ('r45', 'v25', 'confirmo', '2026-11-16 03:25:00+00');
INSERT INTO public.votos_reporte VALUES ('r45', 'v26', 'confirmo', '2026-11-16 04:25:00+00');
INSERT INTO public.votos_reporte VALUES ('r46', 'v24', 'confirmo', '2026-11-18 22:08:00+00');
INSERT INTO public.votos_reporte VALUES ('r47', 'v26', 'confirmo', '2026-11-21 16:51:00+00');
INSERT INTO public.votos_reporte VALUES ('r47', 'v27', 'confirmo', '2026-11-21 17:51:00+00');
INSERT INTO public.votos_reporte VALUES ('r47', 'v28', 'confirmo', '2026-11-21 18:51:00+00');
INSERT INTO public.votos_reporte VALUES ('r48', 'v27', 'confirmo', '2026-11-17 11:34:00+00');
INSERT INTO public.votos_reporte VALUES ('r49', 'v28', 'confirmo', '2026-11-20 06:17:00+00');
INSERT INTO public.votos_reporte VALUES ('r49', 'v29', 'confirmo', '2026-11-20 07:17:00+00');
INSERT INTO public.votos_reporte VALUES ('r49', 'v30', 'confirmo', '2026-11-20 08:17:00+00');
INSERT INTO public.votos_reporte VALUES ('r51', 'v19', 'confirmo', '2026-11-16 20:58:00+00');
INSERT INTO public.votos_reporte VALUES ('r51', 'v20', 'confirmo', '2026-11-16 21:58:00+00');
INSERT INTO public.votos_reporte VALUES ('r53', 'v20', 'confirmo', '2026-11-09 10:24:00+00');
INSERT INTO public.votos_reporte VALUES ('r53', 'v21', 'confirmo', '2026-11-09 11:24:00+00');
INSERT INTO public.votos_reporte VALUES ('r55', 'v23', 'confirmo', '2026-11-19 00:50:00+00');
INSERT INTO public.votos_reporte VALUES ('r55', 'v24', 'confirmo', '2026-11-19 01:50:00+00');
INSERT INTO public.votos_reporte VALUES ('r57', 'v24', 'confirmo', '2026-11-10 14:16:00+00');
INSERT INTO public.votos_reporte VALUES ('r57', 'v25', 'confirmo', '2026-11-10 15:16:00+00');
INSERT INTO public.votos_reporte VALUES ('r59', 'v27', 'confirmo', '2026-11-21 04:42:00+00');
INSERT INTO public.votos_reporte VALUES ('r59', 'v28', 'confirmo', '2026-11-21 05:42:00+00');
INSERT INTO public.votos_reporte VALUES ('r61', 'v28', 'confirmo', '2026-11-12 19:08:00+00');
INSERT INTO public.votos_reporte VALUES ('r61', 'v29', 'confirmo', '2026-11-12 20:08:00+00');
INSERT INTO public.votos_reporte VALUES ('r62', 'v22', 'confirmo', '2026-11-12 23:15:00+00');
INSERT INTO public.votos_reporte VALUES ('r63', 'v23', 'confirmo', '2026-10-30 17:58:00+00');
INSERT INTO public.votos_reporte VALUES ('r63', 'v24', 'confirmo', '2026-10-30 18:58:00+00');
INSERT INTO public.votos_reporte VALUES ('r63', 'v25', 'confirmo', '2026-10-30 19:58:00+00');
INSERT INTO public.votos_reporte VALUES ('r64', 'v23', 'confirmo', '2026-11-15 12:41:00+00');
INSERT INTO public.votos_reporte VALUES ('r65', 'v24', 'confirmo', '2026-11-02 07:24:00+00');
INSERT INTO public.votos_reporte VALUES ('r65', 'v25', 'confirmo', '2026-11-02 08:24:00+00');
INSERT INTO public.votos_reporte VALUES ('r65', 'v26', 'confirmo', '2026-11-02 09:24:00+00');
INSERT INTO public.votos_reporte VALUES ('r66', 'v26', 'confirmo', '2026-11-17 03:07:00+00');
INSERT INTO public.votos_reporte VALUES ('r67', 'v27', 'confirmo', '2026-11-03 21:50:00+00');
INSERT INTO public.votos_reporte VALUES ('r67', 'v28', 'confirmo', '2026-11-03 22:50:00+00');
INSERT INTO public.votos_reporte VALUES ('r67', 'v29', 'confirmo', '2026-11-03 23:50:00+00');
INSERT INTO public.votos_reporte VALUES ('r68', 'v28', 'confirmo', '2026-11-18 16:33:00+00');
INSERT INTO public.votos_reporte VALUES ('r69', 'v28', 'confirmo', '2026-11-06 11:16:00+00');
INSERT INTO public.votos_reporte VALUES ('r69', 'v29', 'confirmo', '2026-11-06 12:16:00+00');
INSERT INTO public.votos_reporte VALUES ('r69', 'v30', 'confirmo', '2026-11-06 13:16:00+00');
INSERT INTO public.votos_reporte VALUES ('r70', 'v30', 'confirmo', '2026-10-24 06:59:00+00');
INSERT INTO public.votos_reporte VALUES ('r71', 'v31', 'confirmo', '2026-11-08 01:42:00+00');
INSERT INTO public.votos_reporte VALUES ('r71', 'v32', 'confirmo', '2026-11-08 02:42:00+00');
INSERT INTO public.votos_reporte VALUES ('r71', 'v33', 'confirmo', '2026-11-08 03:42:00+00');
INSERT INTO public.votos_reporte VALUES ('r72', 'v26', 'confirmo', '2026-11-15 20:15:00+00');
INSERT INTO public.votos_reporte VALUES ('r72', 'v27', 'confirmo', '2026-11-15 21:15:00+00');
INSERT INTO public.votos_reporte VALUES ('r74', 'v28', 'confirmo', '2026-11-14 09:41:00+00');
INSERT INTO public.votos_reporte VALUES ('r74', 'v29', 'confirmo', '2026-11-14 10:41:00+00');
INSERT INTO public.votos_reporte VALUES ('r76', 'v30', 'confirmo', '2026-11-12 00:07:00+00');
INSERT INTO public.votos_reporte VALUES ('r76', 'v31', 'confirmo', '2026-11-12 01:07:00+00');
INSERT INTO public.votos_reporte VALUES ('r78', 'v32', 'confirmo', '2026-11-22 13:33:00+00');
INSERT INTO public.votos_reporte VALUES ('r78', 'v33', 'confirmo', '2026-11-22 14:33:00+00');
INSERT INTO public.votos_reporte VALUES ('r80', 'v34', 'confirmo', '2026-11-20 03:59:00+00');
INSERT INTO public.votos_reporte VALUES ('r80', 'v35', 'confirmo', '2026-11-20 04:59:00+00');
INSERT INTO public.votos_reporte VALUES ('r82', 'v36', 'confirmo', '2026-11-17 17:25:00+00');
INSERT INTO public.votos_reporte VALUES ('r82', 'v1', 'confirmo', '2026-11-17 18:25:00+00');
INSERT INTO public.votos_reporte VALUES ('r84', 'v2', 'confirmo', '2026-11-16 07:51:00+00');
INSERT INTO public.votos_reporte VALUES ('r84', 'v3', 'confirmo', '2026-11-16 08:51:00+00');
INSERT INTO public.votos_reporte VALUES ('r85', 'v30', 'confirmo', '2026-11-09 17:15:00+00');
INSERT INTO public.votos_reporte VALUES ('r85', 'v31', 'confirmo', '2026-11-09 18:15:00+00');
INSERT INTO public.votos_reporte VALUES ('r85', 'v32', 'confirmo', '2026-11-09 19:15:00+00');
INSERT INTO public.votos_reporte VALUES ('r86', 'v31', 'confirmo', '2026-11-16 11:58:00+00');
INSERT INTO public.votos_reporte VALUES ('r87', 'v32', 'confirmo', '2026-11-03 06:41:00+00');
INSERT INTO public.votos_reporte VALUES ('r87', 'v33', 'confirmo', '2026-11-03 07:41:00+00');
INSERT INTO public.votos_reporte VALUES ('r87', 'v34', 'confirmo', '2026-11-03 08:41:00+00');
INSERT INTO public.votos_reporte VALUES ('r88', 'v32', 'confirmo', '2026-11-09 01:24:00+00');
INSERT INTO public.votos_reporte VALUES ('r89', 'v34', 'confirmo', '2026-11-14 21:07:00+00');
INSERT INTO public.votos_reporte VALUES ('r89', 'v35', 'confirmo', '2026-11-14 22:07:00+00');
INSERT INTO public.votos_reporte VALUES ('r89', 'v36', 'confirmo', '2026-11-14 23:07:00+00');
INSERT INTO public.votos_reporte VALUES ('r90', 'v35', 'confirmo', '2026-11-20 15:50:00+00');
INSERT INTO public.votos_reporte VALUES ('r91', 'v36', 'confirmo', '2026-11-08 10:33:00+00');
INSERT INTO public.votos_reporte VALUES ('r91', 'v1', 'confirmo', '2026-11-08 11:33:00+00');
INSERT INTO public.votos_reporte VALUES ('r91', 'v2', 'confirmo', '2026-11-08 12:33:00+00');
INSERT INTO public.votos_reporte VALUES ('r92', 'v1', 'confirmo', '2026-11-14 05:16:00+00');
INSERT INTO public.votos_reporte VALUES ('r93', 'v2', 'confirmo', '2026-11-20 00:59:00+00');
INSERT INTO public.votos_reporte VALUES ('r93', 'v3', 'confirmo', '2026-11-20 01:59:00+00');
INSERT INTO public.votos_reporte VALUES ('r93', 'v4', 'confirmo', '2026-11-20 02:59:00+00');
INSERT INTO public.votos_reporte VALUES ('r94', 'v3', 'confirmo', '2026-11-06 19:42:00+00');
INSERT INTO public.votos_reporte VALUES ('r95', 'v4', 'confirmo', '2026-11-12 14:25:00+00');
INSERT INTO public.votos_reporte VALUES ('r95', 'v5', 'confirmo', '2026-11-12 15:25:00+00');
INSERT INTO public.votos_reporte VALUES ('r95', 'v6', 'confirmo', '2026-11-12 16:25:00+00');
INSERT INTO public.votos_reporte VALUES ('r97', 'v35', 'confirmo', '2026-11-14 08:58:00+00');
INSERT INTO public.votos_reporte VALUES ('r97', 'v36', 'confirmo', '2026-11-14 09:58:00+00');
INSERT INTO public.votos_reporte VALUES ('r99', 'v1', 'confirmo', '2026-10-18 22:24:00+00');
INSERT INTO public.votos_reporte VALUES ('r99', 'v2', 'confirmo', '2026-10-18 23:24:00+00');
INSERT INTO public.votos_reporte VALUES ('r101', 'v3', 'confirmo', '2026-10-25 12:50:00+00');
INSERT INTO public.votos_reporte VALUES ('r101', 'v4', 'confirmo', '2026-10-25 13:50:00+00');
INSERT INTO public.votos_reporte VALUES ('r103', 'v5', 'confirmo', '2026-10-31 02:16:00+00');
INSERT INTO public.votos_reporte VALUES ('r103', 'v6', 'confirmo', '2026-10-31 03:16:00+00');
INSERT INTO public.votos_reporte VALUES ('r105', 'v7', 'confirmo', '2026-11-05 16:42:00+00');
INSERT INTO public.votos_reporte VALUES ('r105', 'v8', 'confirmo', '2026-11-05 17:42:00+00');


--
-- Name: seq_acciones; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.seq_acciones', 18, true);


--
-- Name: seq_alertas; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.seq_alertas', 2, true);


--
-- Name: seq_iniciativas; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.seq_iniciativas', 16, true);


--
-- Name: seq_reportes; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.seq_reportes', 105, true);


--
-- Name: seq_usuarios_municipalidad; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.seq_usuarios_municipalidad', 1, true);


--
-- Name: seq_usuarios_vecinos; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.seq_usuarios_vecinos', 40, true);


--
-- Name: acciones acciones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acciones
    ADD CONSTRAINT acciones_pkey PRIMARY KEY (id);


--
-- Name: alertas alertas_id_barrio_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alertas
    ADD CONSTRAINT alertas_id_barrio_key UNIQUE (id_barrio);


--
-- Name: alertas alertas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alertas
    ADD CONSTRAINT alertas_pkey PRIMARY KEY (id);


--
-- Name: barrios barrios_nombre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.barrios
    ADD CONSTRAINT barrios_nombre_key UNIQUE (nombre);


--
-- Name: barrios barrios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.barrios
    ADD CONSTRAINT barrios_pkey PRIMARY KEY (id);


--
-- Name: codigos_barrio codigos_barrio_codigo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.codigos_barrio
    ADD CONSTRAINT codigos_barrio_codigo_key UNIQUE (codigo);


--
-- Name: codigos_barrio codigos_barrio_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.codigos_barrio
    ADD CONSTRAINT codigos_barrio_pkey PRIMARY KEY (id);


--
-- Name: denuncias_reporte denuncias_reporte_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.denuncias_reporte
    ADD CONSTRAINT denuncias_reporte_pkey PRIMARY KEY (id_reporte, id_usuario);


--
-- Name: iniciativa_participantes iniciativa_participantes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.iniciativa_participantes
    ADD CONSTRAINT iniciativa_participantes_pkey PRIMARY KEY (id_iniciativa, id_usuario);


--
-- Name: iniciativas iniciativas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.iniciativas
    ADD CONSTRAINT iniciativas_pkey PRIMARY KEY (id);


--
-- Name: noticias_leidas noticias_leidas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticias_leidas
    ADD CONSTRAINT noticias_leidas_pkey PRIMARY KEY (id_usuario, id_accion);


--
-- Name: reportes reportes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reportes
    ADD CONSTRAINT reportes_pkey PRIMARY KEY (id);


--
-- Name: usuarios usuarios_correo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_correo_key UNIQUE (correo);


--
-- Name: usuarios usuarios_dni_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_dni_key UNIQUE (dni);


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);


--
-- Name: votos_reporte votos_reporte_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votos_reporte
    ADD CONSTRAINT votos_reporte_pkey PRIMARY KEY (id_reporte, id_usuario);


--
-- Name: idx_acciones_barrio; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_acciones_barrio ON public.acciones USING btree (id_barrio);


--
-- Name: idx_acciones_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_acciones_estado ON public.acciones USING btree (estado);


--
-- Name: idx_acciones_reporte; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_acciones_reporte ON public.acciones USING btree (id_reporte);


--
-- Name: idx_codigos_barrio_barrio; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_codigos_barrio_barrio ON public.codigos_barrio USING btree (id_barrio);


--
-- Name: idx_iniciativas_barrio; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_iniciativas_barrio ON public.iniciativas USING btree (id_barrio);


--
-- Name: idx_iniciativas_creador; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_iniciativas_creador ON public.iniciativas USING btree (id_creador);


--
-- Name: idx_reportes_barrio; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reportes_barrio ON public.reportes USING btree (id_barrio);


--
-- Name: idx_reportes_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reportes_estado ON public.reportes USING btree (estado);


--
-- Name: idx_reportes_fecha; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reportes_fecha ON public.reportes USING btree (fecha DESC);


--
-- Name: idx_reportes_usuario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reportes_usuario ON public.reportes USING btree (id_usuario);


--
-- Name: idx_usuarios_barrio; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_usuarios_barrio ON public.usuarios USING btree (id_barrio);


--
-- Name: idx_usuarios_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_usuarios_estado ON public.usuarios USING btree (estado);


--
-- Name: acciones acciones_id_autoridad_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acciones
    ADD CONSTRAINT acciones_id_autoridad_fkey FOREIGN KEY (id_autoridad) REFERENCES public.usuarios(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: acciones acciones_id_barrio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acciones
    ADD CONSTRAINT acciones_id_barrio_fkey FOREIGN KEY (id_barrio) REFERENCES public.barrios(id) ON UPDATE CASCADE;


--
-- Name: acciones acciones_id_reporte_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acciones
    ADD CONSTRAINT acciones_id_reporte_fkey FOREIGN KEY (id_reporte) REFERENCES public.reportes(id) ON DELETE SET NULL;


--
-- Name: alertas alertas_id_barrio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alertas
    ADD CONSTRAINT alertas_id_barrio_fkey FOREIGN KEY (id_barrio) REFERENCES public.barrios(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: alertas alertas_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alertas
    ADD CONSTRAINT alertas_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: codigos_barrio codigos_barrio_id_barrio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.codigos_barrio
    ADD CONSTRAINT codigos_barrio_id_barrio_fkey FOREIGN KEY (id_barrio) REFERENCES public.barrios(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: denuncias_reporte denuncias_reporte_id_reporte_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.denuncias_reporte
    ADD CONSTRAINT denuncias_reporte_id_reporte_fkey FOREIGN KEY (id_reporte) REFERENCES public.reportes(id) ON DELETE CASCADE;


--
-- Name: denuncias_reporte denuncias_reporte_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.denuncias_reporte
    ADD CONSTRAINT denuncias_reporte_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: iniciativa_participantes iniciativa_participantes_id_iniciativa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.iniciativa_participantes
    ADD CONSTRAINT iniciativa_participantes_id_iniciativa_fkey FOREIGN KEY (id_iniciativa) REFERENCES public.iniciativas(id) ON DELETE CASCADE;


--
-- Name: iniciativa_participantes iniciativa_participantes_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.iniciativa_participantes
    ADD CONSTRAINT iniciativa_participantes_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: iniciativas iniciativas_id_barrio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.iniciativas
    ADD CONSTRAINT iniciativas_id_barrio_fkey FOREIGN KEY (id_barrio) REFERENCES public.barrios(id) ON UPDATE CASCADE;


--
-- Name: iniciativas iniciativas_id_creador_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.iniciativas
    ADD CONSTRAINT iniciativas_id_creador_fkey FOREIGN KEY (id_creador) REFERENCES public.usuarios(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: noticias_leidas noticias_leidas_id_accion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticias_leidas
    ADD CONSTRAINT noticias_leidas_id_accion_fkey FOREIGN KEY (id_accion) REFERENCES public.acciones(id) ON DELETE CASCADE;


--
-- Name: noticias_leidas noticias_leidas_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.noticias_leidas
    ADD CONSTRAINT noticias_leidas_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: reportes reportes_id_barrio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reportes
    ADD CONSTRAINT reportes_id_barrio_fkey FOREIGN KEY (id_barrio) REFERENCES public.barrios(id) ON UPDATE CASCADE;


--
-- Name: reportes reportes_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reportes
    ADD CONSTRAINT reportes_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: usuarios usuarios_id_barrio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_id_barrio_fkey FOREIGN KEY (id_barrio) REFERENCES public.barrios(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: votos_reporte votos_reporte_id_reporte_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votos_reporte
    ADD CONSTRAINT votos_reporte_id_reporte_fkey FOREIGN KEY (id_reporte) REFERENCES public.reportes(id) ON DELETE CASCADE;


--
-- Name: votos_reporte votos_reporte_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votos_reporte
    ADD CONSTRAINT votos_reporte_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict eCgp1N9fh5Jrf1AEH6h1cQ1sg98gkjDM0OY0ktlPQhMFM7htbyajOzt4KwvdDZk

