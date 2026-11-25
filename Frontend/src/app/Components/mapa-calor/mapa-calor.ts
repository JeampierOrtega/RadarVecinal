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
import { NivelTemperatura, ZonaResumen } from '../../Interfaces/zona.interface';

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

/** Fecha relativa corta ("hace 3 min") para el tooltip y el popup. */
function fechaRelativa(fecha: string): string {
  const instante = Date.parse(fecha);
  if (Number.isNaN(instante)) return 'sin fecha';
  const minutos = Math.max(0, Math.round((Date.now() - instante) / 60_000));
  if (minutos < 1) return 'ahora';
  if (minutos < 60) return `hace ${minutos} min`;
  const horas = Math.round(minutos / 60);
  if (horas < 24) return `hace ${horas} h`;
  return `hace ${Math.round(horas / 24)} d`;
}

/** Fecha absoluta legible, sin depender de los pipes de Angular. */
function fechaAbsoluta(fecha: string): string {
  const valor = new Date(fecha);
  if (Number.isNaN(valor.getTime())) return '—';
  return valor.toLocaleString('es-PE', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

function plural(cantidad: number, singular: string, varios: string): string {
  return `${cantidad} ${cantidad === 1 ? singular : varios}`;
}

/** Nivel de temperatura equivalente a la gravedad (chips y barras del popup). */
function nivelDeGravedad(gravedad: number): NivelTemperatura {
  if (gravedad >= 5) return 'rojo';
  if (gravedad >= 3) return 'naranja';
  if (gravedad >= 2) return 'amarillo';
  return 'verde';
}

const ESTADO_POPUP: Record<EstadoReporte, { texto: string; clase: string }> = {
  activo: { texto: 'Activo', clase: 'estado-activo' },
  confirmado: { texto: 'Confirmado', clase: 'estado-confirmado' },
  falso: { texto: 'Falso', clase: 'estado-falso' },
  archivado: { texto: 'Archivado', clase: 'estado-archivado' },
};

/** Crea un nodo con clase y texto: lo que escribe el vecino pasa siempre por textContent. */
function nodo<K extends keyof HTMLElementTagNameMap>(
  etiqueta: K,
  clase?: string,
  texto?: string,
): HTMLElementTagNameMap[K] {
  const elemento = document.createElement(etiqueta);
  if (clase) elemento.className = clase;
  if (texto !== undefined) elemento.textContent = texto;
  return elemento;
}

function filaPopup(icono: string, etiqueta: string, valor: string, claseValor = ''): HTMLElement {
  const fila = nodo('div', 'pr-fila');
  const marca = nodo('i', `bi ${icono}`);
  marca.setAttribute('aria-hidden', 'true');
  fila.append(
    marca,
    nodo('span', 'pr-etiqueta', etiqueta),
    nodo('span', `pr-valor ${claseValor}`.trim(), valor),
  );
  return fila;
}

/** Tooltip de una línea: punto de gravedad + tipo + "hace X". */
function contenidoTooltip(r: ReportePublico): HTMLElement {
  const linea = nodo('span', 'tt-linea');
  linea.append(
    nodo('span', `tt-punto heat-${nivelDeGravedad(r.gravedad)}`),
    nodo('span', 'tt-tipo', ETIQUETA_TIPO[r.tipo]),
    nodo('span', 'tt-hace', fechaRelativa(r.fecha)),
  );
  return linea;
}

/**
 * Tarjeta del popup al hacer clic en un punto. Se construye con DOM y textContent:
 * la descripción la escribe un vecino y nunca se inserta como HTML.
 */
function contenidoPopup(
  r: ReportePublico,
  barrio: string | null,
  verDetalle: () => void,
): HTMLElement {
  const nivel = nivelDeGravedad(r.gravedad);
  const estado = ESTADO_POPUP[r.estado];
  const tarjeta = nodo('div', 'popup-reporte-card');

  const cabecera = nodo('div', 'pr-cabecera');
  const chip = nodo('span', `pr-chip nivel-${nivel}`);
  chip.append(nodo('span', 'pr-punto'), nodo('span', 'pr-tipo', ETIQUETA_TIPO[r.tipo]));
  cabecera.append(chip);

  const descripcion = nodo('p', 'pr-desc', r.descripcion);

  const barra = nodo('div', `pr-barra nivel-${nivel}`);
  const relleno = nodo('span');
  relleno.style.width = `${Math.min(100, Math.max(0, (r.gravedad / 5) * 100))}%`;
  barra.append(relleno);

  const votos = nodo('div', 'pr-votos');
  const voto = (icono: string, texto: string): HTMLElement => {
    const pildora = nodo('span', 'pr-voto');
    const marca = nodo('i', `bi ${icono}`);
    marca.setAttribute('aria-hidden', 'true');
    pildora.append(marca, nodo('span', undefined, texto));
    return pildora;
  };
  votos.append(
    voto('bi-hand-thumbs-up', plural(r.confirmaciones, 'confirmación', 'confirmaciones')),
    voto('bi-hand-thumbs-down', plural(r.incorrectos, 'incorrecto', 'incorrectos')),
  );

  const ver = nodo('button', 'btn btn-sm btn-acento pr-ver');
  ver.type = 'button';
  const iconoVer = nodo('i', 'bi bi-arrow-up-right-circle');
  iconoVer.setAttribute('aria-hidden', 'true');
  ver.append(iconoVer, nodo('span', undefined, 'Ver detalle'));
  ver.addEventListener('click', (evento) => {
    evento.stopPropagation();
    verDetalle();
  });

  const filaEstado = nodo('div', 'pr-fila');
  const marcaEstado = nodo('i', 'bi bi-info-circle');
  marcaEstado.setAttribute('aria-hidden', 'true');
  filaEstado.append(
    marcaEstado,
    nodo('span', 'pr-etiqueta', 'Estado'),
    nodo('span', `pr-estado ${estado.clase}`, estado.texto),
  );

  const filas = nodo('div', 'pr-filas');
  filas.append(
    filaPopup('bi-speedometer2', 'Gravedad', `${r.gravedad}/5`, `nivel-${nivel}`),
    barra,
    filaPopup('bi-clock-history', 'Reportado', fechaRelativa(r.fecha)),
    filaPopup('bi-calendar3', 'Fecha', fechaAbsoluta(r.fecha)),
    filaEstado,
    filaPopup('bi-geo-alt', 'Barrio', barrio ?? r.id_barrio),
  );

  tarjeta.append(cabecera, descripcion, filas, votos, ver);
  return tarjeta;
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
  /** Clic en una zona vacía del mapa (sin barrio ni punto): cierra el panel abierto. */
  readonly fondoClick = output<void>();

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
  private popupAbierto?: Leaflet.Popup;
  private temporizadorRedimension?: ReturnType<typeof setTimeout>;
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

      // Los tooltips de reportes van sobre los paneles flotantes; las etiquetas de
      // barrio se quedan debajo (si no, los nombres se pintarían encima de las tarjetas).
      this.mapa.createPane('tooltip-reportes').style.zIndex = '850';

      this.mapa.on('click', (e: Leaflet.LeafletMouseEvent) => {
        if (this.elegir()) {
          this.puntoElegido.emit({ lat: e.latlng.lat, lng: e.latlng.lng });
          return;
        }
        // Clic en zona vacía: la pantalla cierra el panel del barrio.
        this.fondoClick.emit();
      });

      // Los márgenes del autoPan dependen de los paneles: se recalculan al redimensionar.
      window.addEventListener('resize', this.alRedimensionar, { passive: true });

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
    clearTimeout(this.temporizadorRedimension);
    if (typeof window !== 'undefined') window.removeEventListener('resize', this.alRedimensionar);
    this.mapa?.remove();
  }

  /** Respeta la preferencia del sistema de reducir animaciones. */
  private prefiereMenosMovimiento(): boolean {
    return (
      typeof window !== 'undefined' &&
      window.matchMedia('(prefers-reduced-motion: reduce)').matches
    );
  }

  /** Al cambiar el tamaño de la ventana se recalculan los márgenes del popup abierto. */
  private readonly alRedimensionar = (): void => {
    clearTimeout(this.temporizadorRedimension);
    this.temporizadorRedimension = setTimeout(() => {
      const popup = this.popupAbierto;
      if (!this.mapa || !popup || !popup.isOpen()) return;
      const margenes = this.margenesAutoPan();
      popup.options.autoPanPaddingTopLeft = margenes.topLeft;
      popup.options.autoPanPaddingBottomRight = margenes.bottomRight;
      const destino = popup.getLatLng();
      if (destino) {
        this.mapa.panInside(destino, {
          paddingTopLeft: margenes.topLeft,
          paddingBottomRight: margenes.bottomRight,
          animate: !this.prefiereMenosMovimiento(),
        });
      }
    }, 120);
  };

  /** Rectángulos actuales de los paneles superpuestos (medidos en vivo). */
  private panelesSuperpuestos(): { tipo: string; caja: DOMRect }[] {
    const host = this.contenedor().nativeElement.closest('.pantalla');
    if (!host) return [];
    return Array.from(host.querySelectorAll<HTMLElement>('[data-panel]')).map((elemento) => ({
      tipo: elemento.dataset['panel'] ?? '',
      caja: elemento.getBoundingClientRect(),
    }));
  }

  /** Márgenes del autoPan para que el popup no quede debajo de ningún panel. */
  private margenesAutoPan(): {
    topLeft: [number, number];
    bottomRight: [number, number];
  } {
    const contenedor = this.contenedor().nativeElement;
    const mapa = contenedor.getBoundingClientRect();
    const ancho = mapa.width || 1;
    const alto = mapa.height || 1;
    let arriba = 0;
    let izquierda = 0;
    let derecha = 0;
    let abajo = 0;

    for (const { tipo, caja } of this.panelesSuperpuestos()) {
      if (!caja.width || !caja.height) continue;
      switch (tipo) {
        case 'filtros':
        case 'aviso':
          arriba = Math.max(arriba, caja.bottom - mapa.top + 10);
          break;
        case 'derecha':
          derecha = Math.max(derecha, mapa.right - caja.left + 10);
          break;
        case 'controles':
          // En escritorio van al borde izquierdo; en móvil, al derecho.
          if (caja.left > mapa.left + ancho / 2) {
            derecha = Math.max(derecha, mapa.right - caja.left + 10);
          } else {
            izquierda = Math.max(izquierda, caja.right - mapa.left + 10);
          }
          break;
        case 'leyenda':
        case 'acciones':
          abajo = Math.max(abajo, mapa.bottom - caja.top + 10);
          break;
        case 'hoja':
          // Hoja inferior: solo cuenta cuando ocupa casi todo el ancho (móvil).
          if (caja.width >= ancho * 0.55) {
            abajo = Math.max(abajo, mapa.bottom - caja.top + 10);
          }
          break;
      }
    }

    // Nunca dejar el área visible en menos de ~24 % del mapa.
    const limiteY = alto * 0.38;
    const limiteX = ancho * 0.38;
    return {
      topLeft: [Math.min(izquierda, limiteX), Math.min(arriba, limiteY)],
      bottomRight: [Math.min(derecha, limiteX), Math.min(abajo, limiteY)],
    };
  }

  /** Arriba por defecto; abajo si el punto está junto al borde superior o a un panel. */
  private direccionTooltip(lat: number, lng: number): 'top' | 'bottom' {
    const mapa = this.mapa;
    if (!mapa) return 'top';
    const contenedor = this.contenedor().nativeElement;
    const punto = mapa.latLngToContainerPoint([lat, lng]);
    const cajaMapa = contenedor.getBoundingClientRect();
    const alto = cajaMapa.height || 1;
    let limite = 56;

    for (const { tipo, caja } of this.panelesSuperpuestos()) {
      if (!caja.width || !caja.height) continue;
      if (tipo !== 'filtros' && tipo !== 'aviso' && tipo !== 'derecha') continue;
      const desdeArriba = caja.bottom - cajaMapa.top;
      if (desdeArriba > alto * 0.55) continue;
      const dentroX =
        punto.x >= caja.left - cajaMapa.left - 16 && punto.x <= caja.right - cajaMapa.left + 16;
      if (dentroX) limite = Math.max(limite, desdeArriba + 14);
    }

    return punto.y <= limite ? 'bottom' : 'top';
  }

  /** Abre la tarjeta de un reporte con los márgenes reales de los paneles. */
  private abrirPopupReporte(reporte: ReportePublico, destino: Leaflet.LatLng): void {
    if (!this.mapa) return;
    const margenes = this.margenesAutoPan();
    const barrio = this.zonas().find((z) => z.id === reporte.id_barrio)?.nombre ?? null;
    this.popupAbierto = this.L.popup({
      className: 'popup-reporte',
      minWidth: 280,
      maxWidth: 320,
      autoPan: true,
      keepInView: true,
      autoPanPaddingTopLeft: margenes.topLeft,
      autoPanPaddingBottomRight: margenes.bottomRight,
      closeButton: true,
      offset: [0, -6],
    })
      .setLatLng(destino)
      .setContent(
        contenidoPopup(reporte, barrio, () => {
          this.mapa?.closePopup();
          this.reporteClick.emit(reporte.id);
        }),
      )
      .openOn(this.mapa);
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
    this.mapa.flyToBounds(limites, {
      padding: [28, 28],
      duration: this.prefiereMenosMovimiento() ? 0 : 0.6,
    });
  }

  /** Centra el mapa en un barrio concreto (buscador del mapa). */
  centrarBarrio(zona: ZonaResumen): void {
    if (!this.mapa) return;
    this.mapa.flyToBounds(this.L.latLngBounds(zona.poligono), {
      padding: [40, 40],
      maxZoom: 16,
      duration: this.prefiereMenosMovimiento() ? 0 : 0.6,
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
          this.mapa!.flyTo([punto.lat, punto.lng], 16, {
            duration: this.prefiereMenosMovimiento() ? 0 : 0.7,
          });
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
          .on('click', (e: Leaflet.LeafletMouseEvent) => {
            L.DomEvent.stopPropagation(e.originalEvent);
            this.zonaClick.emit(zona.id);
          });
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
          .on('click', (e: Leaflet.LeafletMouseEvent) => {
            L.DomEvent.stopPropagation(e.originalEvent);
            this.accionClick.emit(accion.id);
          })
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
          .bindTooltip(contenidoTooltip(reporte), {
            direction: this.direccionTooltip(reporte.lat, reporte.lng),
            offset: [0, -2],
            className: 'tooltip-reporte',
            pane: 'tooltip-reportes',
            opacity: 1,
          })
          .on('click', (e: Leaflet.LeafletMouseEvent) => {
            // El clic abre la tarjeta; "Ver detalle" emite reporteClick.
            L.DomEvent.stopPropagation(e.originalEvent);
            this.abrirPopupReporte(reporte, e.latlng);
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
