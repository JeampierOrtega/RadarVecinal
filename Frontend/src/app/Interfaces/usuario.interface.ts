// Los nombres de los campos coinciden con los del backend (snake_case).

export type Rol = 'vecino' | 'municipalidad';
export type EstadoUsuario = 'Pendiente' | 'Verificado' | 'Rechazado' | 'Suspendido' | 'Baneado';

export interface Usuario {
  id: string;
  nombre: string;
  dni?: string | null;
  correo: string;
  rol: Rol;
  id_barrio: string | null;
  estado: EstadoUsuario;
  fecha_registro: string;
  institucion: string | null;
  strikes: number;
  suspendido_hasta?: string | null;
  motivo_sancion?: string | null;
}

export interface ModerarUsuarioDatos {
  accion: 'suspender' | 'banear' | 'reactivar';
  dias?: number;
  motivo?: string;
}

export interface LoginDatos {
  correo: string;
  clave: string;
}

export interface RegistroDatos {
  nombre: string;
  dni: string;
  correo: string;
  clave: string;
  id_barrio: string;
  codigo_barrio: string;
}
