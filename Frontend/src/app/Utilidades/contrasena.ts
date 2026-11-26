/** Evaluación local de la fortaleza de una contraseña durante el registro. */

export type NivelClave = 'muy-debil' | 'debil' | 'media' | 'fuerte';

export interface CriterioClave {
  id: 'longitud' | 'mayuscula' | 'numero' | 'simbolo';
  etiqueta: string;
  cumple: boolean;
}

export interface FortalezaClave {
  puntaje: number;
  nivel: NivelClave;
  etiqueta: string;
  criterios: CriterioClave[];
  valida: boolean;
}

export const SIMBOLOS_CLAVE = '!@#$%^&*(),.?":{}|<>_-';

const ETIQUETAS: Record<NivelClave, string> = {
  'muy-debil': 'Muy débil',
  debil: 'Débil',
  media: 'Media',
  fuerte: 'Fuerte',
};

export function evaluarClave(clave: string): FortalezaClave {
  const criterios: CriterioClave[] = [
    {
      id: 'longitud',
      etiqueta: 'Mínimo 8 caracteres',
      cumple: clave.length >= 8,
    },
    {
      id: 'mayuscula',
      etiqueta: 'Una letra mayúscula (A-Z)',
      cumple: /[A-Z]/.test(clave),
    },
    {
      id: 'numero',
      etiqueta: 'Un número (0-9)',
      cumple: /[0-9]/.test(clave),
    },
    {
      id: 'simbolo',
      etiqueta: 'Un símbolo (!@#$%^&*… )',
      cumple: [...clave].some((caracter) => SIMBOLOS_CLAVE.includes(caracter)),
    },
  ];

  const puntaje = criterios.filter((criterio) => criterio.cumple).length;
  const nivel: NivelClave =
    puntaje <= 1 ? 'muy-debil' : puntaje === 2 ? 'debil' : puntaje === 3 ? 'media' : 'fuerte';

  return {
    puntaje,
    nivel,
    etiqueta: ETIQUETAS[nivel],
    criterios,
    valida: puntaje === 4,
  };
}
