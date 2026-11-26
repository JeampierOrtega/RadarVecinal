import { evaluarClave } from './contrasena';

describe('evaluarClave', () => {
  it('acepta una clave con los cuatro requisitos', () => {
    const resultado = evaluarClave('Radar2026!');

    expect(resultado.valida).toBe(true);
    expect(resultado.puntaje).toBe(4);
    expect(resultado.nivel).toBe('fuerte');
  });

  it('rechaza claves sin mayúscula, número o símbolo', () => {
    expect(evaluarClave('radar2026!').valida).toBe(false);
    expect(evaluarClave('RadarSegura!').valida).toBe(false);
    expect(evaluarClave('Radar2026').valida).toBe(false);
    expect(evaluarClave('Corta1!').valida).toBe(false);
  });

  it('marca cada criterio de forma independiente', () => {
    const resultado = evaluarClave('Radar2026!');

    expect(resultado.criterios.every((criterio) => criterio.cumple)).toBe(true);
  });
});
