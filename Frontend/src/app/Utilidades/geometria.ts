/** Utilidades geográficas puras para ubicar un punto dentro de los barrios del mapa. */

export type Coordenada = readonly [number, number];

/**
 * Algoritmo Ray-Casting: cuenta cuántas veces un rayo horizontal desde el punto
 * cruza los bordes del polígono. Los vértices llegan como [latitud, longitud].
 */
export function puntoEnPoligono(
  lat: number,
  lng: number,
  poligono: readonly Coordenada[],
): boolean {
  let dentro = false;

  for (let i = 0, j = poligono.length - 1; i < poligono.length; j = i++) {
    const [lat1, lng1] = poligono[i];
    const [lat2, lng2] = poligono[j];

    if (lat1 > lat !== lat2 > lat && lng < ((lng2 - lng1) * (lat - lat1)) / (lat2 - lat1) + lng1) {
      dentro = !dentro;
    }
  }

  return dentro;
}

/** Primera zona cuyo polígono contiene el punto (mismo criterio que el backend). */
export function buscarZona<T extends { poligono: readonly Coordenada[] }>(
  zonas: readonly T[],
  lat: number,
  lng: number,
): T | undefined {
  return zonas.find((zona) => puntoEnPoligono(lat, lng, zona.poligono));
}
