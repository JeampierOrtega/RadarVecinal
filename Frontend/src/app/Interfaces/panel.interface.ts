import { Accion } from './accion.interface';
import { ReportePublico } from './reporte.interface';
import { Usuario } from './usuario.interface';
import { PuntoCaliente, ZonaResumen } from './zona.interface';

export interface Alerta {
  id: string;
  id_barrio: string;
  inicio: string;
  expira: string;
  id_usuario?: string | null;
  autor_nombre?: string | null;
  autor_dni?: string | null;
  nombre_barrio?: string | null;
  minutos_restantes?: number | null;
}

export interface PanelMunicipal {
  zonas: ZonaResumen[];
  criticos: ZonaResumen[];
  acciones: Accion[];
  propias: Accion[];
  pendientes?: Usuario[];
  vecinos: Usuario[];
  alertas: Alerta[];
  reportes: ReportePublico[];
  puntos: PuntoCaliente[];
}

export interface MiBarrio {
  zona: ZonaResumen | null;
  reportes: ReportePublico[];
  noticias: Accion[];
}
