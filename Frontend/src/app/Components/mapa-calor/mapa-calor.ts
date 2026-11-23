import {
  Component,
  ElementRef,
  OnDestroy,
  afterNextRender,
  effect,
  input,
  output,
  signal,
  viewChild,
} from '@angular/core';
import type * as Leaflet from 'leaflet';

import { Accion } from '../../Interfaces/accion.interface';
import { CENTRO_HUANCAYO, COLOR_NIVEL, ETIQUETA_TIPO } from '../../Interfaces/constantes';
import { Alerta } from '../../Interfaces/panel.interface';
import { EstadoReporte, ReportePublico } from '../../Interfaces/reporte.interface';
import { ZonaResumen } from '../../Interfaces/zona.interface';

export interface Punto {
  lat: number;
  lng: number;
}

export type BaseMapa = 'mapa' | 'satelite';

/** Mismo cálculo base del backend (gravedad × confirmaciones × 0.5^(días/15)), sin el
 * bono de novedad: ese es por barrio y con tope. */
function pesoReporte(r: ReportePublico): number {
  const dias = Math.max(0, (Date.now() - new Date(r.fecha).getTime()) / 86_400_000);
  const factor = 1 + (Math.min(Math.max(r.confirmaciones, 0), 3) / 3) * 0.5;
  return r.gravedad * factor * Math.pow(0.5, dias / 15);
}

const ETIQUETA_ESTADO: Record<EstadoReporte, string> = {
  activo: 'Activo',
  confirmado: 'Confirmado',
  falso: 'Falso',
  archivado: 'Archivado',
};

/** Fecha relativa corta ("hace 3 min") para el tooltip del punto. */
function fechaRelativa(fecha: string): string {
  const minutos = Math.max(0, Math.round((Date.now() - Date.parse(fecha)) / 60_000));
  if (minutos < 1) return 'ahora';
  if (minutos < 60) return `hace ${minutos} min`;
  const horas = Math.round(minutos / 60);
  if (horas < 24) return `hace ${horas} h`;
  return `hace ${Math.round(horas / 24)} d`;
}

/**
 * Contenido del tooltip construido con DOM y textContent: la descripción la escribe
 * un vecino, así que nunca se inserta como HTML (evita XSS).
 */
function contenidoReporte(r: ReportePublico): HTMLElement {
  const caja = document.createElement('div');
  const titulo = document.createElement('strong');
  titulo.className = 'tooltip-reporte-titulo';
  titulo.textContent = ETIQUETA_TIPO[r.tipo];
  const descripcion = document.createElement('span');
  descripcion.className = 'tooltip-reporte-desc';
  descripcion.textContent = r.descripcion;
  const meta = document.createElement('span');
  meta.className = 'tooltip-reporte-meta';
  meta.textContent = `Gravedad ${r.gravedad}/5 · ${fechaRelativa(r.fecha)} · ${ETIQUETA_ESTADO[r.estado]}`;
  caja.append(titulo, descripcion, meta);
  return caja;
}

function mmss(segundos: number): string {
  const m = Math.floor(segundos / 60)
    .toString()
    .padStart(2, '0');
  const s = (segundos % 60).toString().padStart(2, '0');
  return `${m}:${s}`;
}

/**
 * Mapa de Huancayo con Leaflet: barrios coloreados, capa de calor, puntos de reportes,
 * marcadores de respuesta oficial y barrios EN ALERTA. También sirve para elegir un punto.
 * Leaflet solo funciona en el navegador, por eso se carga dentro de afterNextRender.
 */
@Component({
  selector: 'app-mapa-calor',
  template:
    '<div #contenedor class="mapa" role="application" aria-label="Mapa de calor de Huancayo"></div>',
  styles:
    ':host { display: block; height: 100%; } .mapa { height: 100%; width: 100%; min-height: 240px; }',
})
export class MapaCalor implements OnDestroy {
  readonly zonas = input<ZonaResumen[]>([]);
  readonly reportes = input<ReportePublico[]>([]);
  readonly acciones = input<Accion[]>([]);
  readonly alertas = input<Alerta[]>([]);
  readonly seleccion = input<string | null>(null);
  /** true = modo "elegir punto" (formulario de reporte). */
  readonly elegir = input(false);
  readonly punto = input<Punto | null>(null);

  readonly zonaClick = output<string>();
  readonly reporteClick = output<string>();
  readonly accionClick = output<string>();
  readonly puntoElegido = output<Punto>();

  private readonly contenedor = viewChild.required<ElementRef<HTMLDivElement>>('contenedor');
  private readonly listo = signal(false);
  private L!: typeof Leaflet;
  private HeatLayer!: typeof import('leaflet.heat').HeatLayer;
  private mapa?: Leaflet.Map;
  private capas?: Leaflet.LayerGroup;
  private capasAlerta?: Leaflet.LayerGroup;
  private capaCalor?: Leaflet.Layer;
  private rendererBarrios?: Leaflet.Renderer;
  private rendererAlertas?: Leaflet.Renderer;
  private rendererPuntos?: Leaflet.Renderer;
  private baseMapa?: Leaflet.TileLayer;
  private baseSatelite?: Leaflet.TileLayer;
  private etiquetasSatelite?: Leaflet.TileLayer;
  private ubicacion?: Leaflet.LayerGroup;
  private limitesCiudad?: Leaflet.LatLngBounds;
  private temporizador?: ReturnType<typeof setInterval>;
  private encuadreHecho = false;
  private readonly ahora = signal(Date.now());
  private base: BaseMapa = 'mapa';

  constructor() {
    afterNextRender(async () => {
      const leaflet = await import('leaflet');
      this.L = (leaflet as unknown as { default: typeof Leaflet }).default ?? leaflet;
      // Capa de calor (plugin leaflet.heat): se guarda su clase para crear la capa luego.
      this.HeatLayer = (await import('leaflet.heat')).HeatLayer;

      this.mapa = this.L.map(this.contenedor().nativeElement, {
        center: [CENTRO_HUANCAYO.lat, CENTRO_HUANCAYO.lng],
        zoom: 13,
        minZoom: 11,
        maxZoom: 19,
        zoomControl: false,
        zoomSnap: 0.5,
        zoomDelta: 0.5,
        preferCanvas: true,
        worldCopyJump: true,
      });

      // Capas base: mapa de calles (por defecto) y satélite, como en Google Maps.
      this.baseMapa = this.L.tileLayer(
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
        {
          attribution:
            'Tiles © <a href="https://www.esri.com/">Esri</a> · Esri, HERE, Garmin, © OpenStreetMap',
          maxZoom: 19,
        },
      ).addTo(this.mapa);

      this.baseSatelite = this.L.tileLayer(
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
        {
          attribution:
            'Tiles © <a href="https://www.esri.com/">Esri</a> · Maxar, Earthstar Geographics',
          maxZoom: 19,
        },
      );

      this.etiquetasSatelite = this.L.tileLayer(
        'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
        { maxZoom: 19, opacity: 0.9 },
      );

      this.mapa.attributionControl.setPrefix(
        '<a href="https://leafletjs.com" target="_blank" rel="noopener">Leaflet</a>',
      );
      this.L.control
        .scale({ position: 'bottomright', imperial: false, maxWidth: 120 })
        .addTo(this.mapa);

      // Panes propios con z-index explícito, de abajo hacia arriba:
      // barrios < calor < alertas < puntos de reportes. Cada pane necesita su propio
      // renderer (con preferCanvas todos los vectores comparten un único canvas y el
      // z-index de los panes no serviría de nada). Los renderers son SVG para que solo
      // capture el ratón lo que está dibujado: los puntos no tapan los barrios de abajo.
      const panes: [string, string][] = [
        ['barrios', '350'],
        ['calor', '380'],
        ['alertas', '410'],
        ['puntos', '640'], // por debajo de tooltipPane (650), para que el tooltip se vea
      ];
      for (const [nombre, z] of panes) {
        this.mapa.createPane(nombre).style.zIndex = z;
      }
      this.rendererBarrios = this.L.svg({ pane: 'barrios' });
      this.rendererAlertas = this.L.svg({ pane: 'alertas' });
      this.rendererPuntos = this.L.svg({ pane: 'puntos' });

      this.capas = this.L.layerGroup().addTo(this.mapa);
      this.capasAlerta = this.L.layerGroup().addTo(this.mapa);
      this.ubicacion = this.L.layerGroup().addTo(this.mapa);

      this.mapa.on('click', (e: Leaflet.LeafletMouseEvent) => {
        if (this.elegir()) this.puntoElegido.emit({ lat: e.latlng.lat, lng: e.latlng.lng });
      });

      // Cuenta regresiva de las alertas: se actualiza cada segundo.
      this.temporizador = setInterval(() => this.ahora.set(Date.now()), 1000);
      this.listo.set(true);
    });

    // Se vuelve a dibujar cada vez que cambia alguna entrada (zonas, reportes, selección...).
    effect(() => {
      if (!this.listo()) return;
      this.dibujar();
    });
    effect(() => {
      if (!this.listo()) return;
      this.dibujarAlertas();
    });
  }

  ngOnDestroy(): void {
    clearInterval(this.temporizador);
    this.mapa?.remove();
  }

  // --- Controles que usa la pantalla del mapa (estilo Google Maps) ---

  /** Cambia entre el mapa de calles y la vista satelital. */
  cambiarBase(base: BaseMapa): void {
    if (!this.mapa || !this.baseMapa || !this.baseSatelite) return;
    if (this.base === base) return;
    this.base = base;
    if (base === 'satelite') {
      this.mapa.removeLayer(this.baseMapa);
      this.baseSatelite.addTo(this.mapa);
      this.etiquetasSatelite?.addTo(this.mapa);
    } else {
      this.mapa.removeLayer(this.baseSatelite);
      this.etiquetasSatelite?.remove();
      this.baseMapa.addTo(this.mapa);
    }
  }

  acercar(): void {
    this.mapa?.zoomIn(1);
  }

  alejar(): void {
    this.mapa?.zoomOut(1);
  }

  /** Vuelve a encuadrar todos los barrios (botón "ver toda la ciudad"). */
  verCiudad(zonas: ZonaResumen[] = this.zonas()): void {
    if (!this.mapa) return;
    const limites =
      this.limitesCiudad ??
      (zonas.length ? this.L.latLngBounds(zonas.flatMap((z) => z.poligono)) : null);
    if (!limites) return;
    this.limitesCiudad = limites;
    this.mapa.flyToBounds(limites, { padding: [28, 28], duration: 0.6 });
  }

  /** Centra el mapa en un barrio concreto (buscador del mapa). */
  centrarBarrio(zona: ZonaResumen): void {
    if (!this.mapa) return;
    this.mapa.flyToBounds(this.L.latLngBounds(zona.poligono), {
      padding: [40, 40],
      maxZoom: 16,
      duration: 0.6,
    });
  }

  /** Pide la ubicación al navegador y la muestra con un punto azul. */
  miUbicacion(): Promise<Punto> {
    return new Promise((resolver, rechazar) => {
      if (!this.mapa || !this.ubicacion) {
        rechazar(new Error('El mapa todavía no está listo.'));
        return;
      }
      if (!('geolocation' in navigator)) {
        rechazar(new Error('Tu navegador no permite compartir la ubicación.'));
        return;
      }
      navigator.geolocation.getCurrentPosition(
        (posicion) => {
          const punto = { lat: posicion.coords.latitude, lng: posicion.coords.longitude };
          this.ubicacion!.clearLayers();
          this.L.circleMarker([punto.lat, punto.lng], {
            radius: 8,
            color: '#ffffff',
            weight: 3,
            fillColor: '#2563eb',
            fillOpacity: 1,
          })
            .bindTooltip('Estás aquí', { direction: 'top' })
            .addTo(this.ubicacion!);
          this.L.circle([punto.lat, punto.lng], {
            radius: Math.min(posicion.coords.accuracy || 60, 400),
            color: '#2563eb',
            weight: 1,
            fillColor: '#2563eb',
            fillOpacity: 0.14,
          }).addTo(this.ubicacion!);
          this.mapa!.flyTo([punto.lat, punto.lng], 16, { duration: 0.7 });
          resolver(punto);
        },
        (error) => {
          rechazar(
            new Error(
              error.code === error.PERMISSION_DENIED
                ? 'No diste permiso para usar tu ubicación. Actívalo en el navegador e inténtalo de nuevo.'
                : 'No pudimos obtener tu ubicación. Revisa tu conexión e inténtalo de nuevo.',
            ),
          );
        },
        { enableHighAccuracy: true, timeout: 10_000, maximumAge: 60_000 },
      );
    });
  }

  // --- Dibujo ---
  /**
   * Barrios EN ALERTA: borde rojo parpadeante con cuenta regresiva. Va en su propia capa
   * porque se actualiza cada segundo y no queremos redibujar todo el mapa.
   */
  private dibujarAlertas(): void {
    const L = this.L;
    const capa = this.capasAlerta!;
    const zonas = this.zonas();
    const alertas = this.alertas();
    const ahora = alertas.length ? this.ahora() : 0; // solo se vuelve a ejecutar si hay alertas
    capa.clearLayers();
    if (this.elegir()) return;

    for (const alerta of alertas) {
      const zona = zonas.find((z) => z.id === alerta.id_barrio);
      const segundos = Math.max(0, Math.ceil((Date.parse(alerta.expira) - ahora) / 1000));
      if (!zona || segundos <= 0) continue;
      // No interactivo: el clic lo sigue resolviendo el polígono del barrio, y así esta
      // capa (que se redibuja cada segundo) no roba el hover de los puntos de reportes.
      L.polygon(zona.poligono, {
        renderer: this.rendererAlertas,
        color: COLOR_NIVEL.rojo,
        weight: 5,
        fill: false,
        interactive: false,
        className: 'barrio-en-alerta',
      })
        .bindTooltip(`${zona.nombre} · EN ALERTA ${mmss(segundos)}`, {
          permanent: true,
          direction: 'center',
          interactive: false,
        })
        .addTo(capa);
    }
  }

  private dibujar(): void {
    const L = this.L;
    const mapa = this.mapa!;
    const capas = this.capas!;
    const zonas = this.zonas();
    const seleccion = this.seleccion();
    const elegir = this.elegir();
    // OJO: este método no debe leer `ahora`. El temporizador de cada segundo solo
    // alimenta dibujarAlertas(); los barrios y los puntos solo cambian con los datos.
    capas.clearLayers();

    // Barrios coloreados según su temperatura
    for (const zona of zonas) {
      const color = COLOR_NIVEL[zona.nivel];
      const poligono = L.polygon(zona.poligono, {
        renderer: this.rendererBarrios,
        color,
        fillColor: color,
        fillOpacity: seleccion === zona.id ? 0.38 : 0.22,
        weight: seleccion === zona.id ? 3 : 1.5,
        opacity: 0.92,
        dashArray: zona.nivel === 'verde' ? '3 5' : undefined,
      }).addTo(capas);
      if (!elegir) {
        // Etiqueta fija con el nombre: el mapa queda "lleno" de información útil.
        // No interactiva, para que no estorbe al pasar el ratón por los puntos.
        poligono
          .bindTooltip(zona.nombre, {
            permanent: true,
            direction: 'center',
            interactive: false,
            className: 'etiqueta-barrio',
            opacity: 0.95,
          })
          .on('click', () => this.zonaClick.emit(zona.id));
      }
    }

    // La primera vez se encuadra toda la ciudad para que se vean todos los barrios.
    if (!this.encuadreHecho && zonas.length) {
      this.limitesCiudad = L.latLngBounds(zonas.flatMap((z) => z.poligono));
      mapa.fitBounds(this.limitesCiudad, { padding: [26, 26] });
      this.encuadreHecho = true;
    }

    // Capa de calor (reportes que no son falsos ni archivados)
    if (this.capaCalor) mapa.removeLayer(this.capaCalor);
    const puntosCalor = this.reportes()
      .filter((r) => r.estado !== 'falso' && r.estado !== 'archivado')
      .map((r) => [r.lat, r.lng, pesoReporte(r)] as [number, number, number]);
    this.capaCalor = (
      new this.HeatLayer(puntosCalor, {
        pane: 'calor',
        radius: 32,
        blur: 25,
        max: 8,
        maxZoom: 15,
        minOpacity: 0.12,
        gradient: {
          0.2: COLOR_NIVEL.verde,
          0.45: COLOR_NIVEL.amarillo,
          0.7: COLOR_NIVEL.naranja,
          1: COLOR_NIVEL.rojo,
        },
      }) as unknown as Leaflet.Layer
    ).addTo(mapa);

    if (!elegir) {
      // Marcador de "respuesta oficial" en los barrios con una acción en curso o planificada
      for (const zona of zonas) {
        const accion = this.acciones()
          .filter((a) => a.id_barrio === zona.id && a.estado !== 'Completada')
          .sort((a, b) => b.fecha.localeCompare(a.fecha))[0];
        const esquina = zona.poligono[0];
        if (!accion || !esquina) continue;
        L.marker(esquina, {
          icon: L.divIcon({
            className: 'marcador-oficial',
            html: '<span title="Respuesta oficial"><i class="bi bi-shield-check"></i></span>',
            iconSize: [30, 30],
          }),
        })
          .bindTooltip(`${accion.titulo} · ${accion.estado}`)
          .on('click', () => this.accionClick.emit(accion.id))
          .addTo(capas);
      }

      // Cada reporte es un punto clicable; el color y el tamaño reflejan su gravedad.
      for (const reporte of this.reportes()) {
        L.circleMarker([reporte.lat, reporte.lng], {
          renderer: this.rendererPuntos,
          radius: 3.4 + Math.min(reporte.gravedad, 5) * 0.42,
          color: '#ffffff',
          fillColor: this.colorGravedad(reporte.gravedad),
          fillOpacity: 0.92,
          weight: 1.3,
        })
          .bindTooltip(contenidoReporte(reporte), {
            direction: 'top',
            offset: [0, -2],
            className: 'tooltip-reporte',
          })
          .on('click', (e: Leaflet.LeafletMouseEvent) => {
            L.DomEvent.stopPropagation(e.originalEvent);
            this.reporteClick.emit(reporte.id);
          })
          .addTo(capas);
      }
    }

    // Punto elegido en el formulario
    const punto = this.punto();
    if (punto) {
      L.circleMarker([punto.lat, punto.lng], {
        renderer: this.rendererPuntos,
        radius: 9,
        color: COLOR_NIVEL.rojo,
        fillOpacity: 0.9,
        weight: 3,
      }).addTo(capas);
      mapa.panTo([punto.lat, punto.lng]);
    }
  }

  /** Color del punto según la gravedad base del incidente. */
  private colorGravedad(gravedad: number): string {
    if (gravedad >= 5) return COLOR_NIVEL.rojo;
    if (gravedad >= 3) return COLOR_NIVEL.naranja;
    if (gravedad >= 2) return COLOR_NIVEL.amarillo;
    return COLOR_NIVEL.verde;
  }
}
