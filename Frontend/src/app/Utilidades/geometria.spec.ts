import { buscarZona, puntoEnPoligono } from './geometria';

const CUADRADO: [number, number][] = [
  [-12.06, -75.21],
  [-12.06, -75.19],
  [-12.05, -75.19],
  [-12.05, -75.21],
];

describe('puntoEnPoligono', () => {
  it('detecta un punto dentro del polígono', () => {
    expect(puntoEnPoligono(-12.055, -75.2, CUADRADO)).toBe(true);
  });

  it('detecta un punto fuera del polígono', () => {
    expect(puntoEnPoligono(-12.07, -75.2, CUADRADO)).toBe(false);
    expect(puntoEnPoligono(-12.055, -75.18, CUADRADO)).toBe(false);
  });
});

describe('buscarZona', () => {
  it('devuelve la zona que contiene el punto', () => {
    const zonas = [
      { id: 'b1', poligono: CUADRADO },
      {
        id: 'b2',
        poligono: [
          [-12.05, -75.19],
          [-12.05, -75.17],
          [-12.04, -75.17],
          [-12.04, -75.19],
        ] as [number, number][],
      },
    ];

    expect(buscarZona(zonas, -12.055, -75.2)?.id).toBe('b1');
    expect(buscarZona(zonas, -12.045, -75.18)?.id).toBe('b2');
    expect(buscarZona(zonas, 0, 0)).toBeUndefined();
  });
});
