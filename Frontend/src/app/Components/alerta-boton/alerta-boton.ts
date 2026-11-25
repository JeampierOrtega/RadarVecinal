import { Component, inject, output, signal } from '@angular/core';

import { NotificacionesService } from '../../Services/notificaciones.service';
import { PanelesService } from '../../Services/paneles.service';

/** Botón "Alerta de barrio": un vecino activa una alerta de 30 minutos en su barrio. */
@Component({
  selector: 'app-alerta-boton',
  template: `<button class="btn btn-danger shadow" [disabled]="activando()" (click)="activar()">
    @if (activando()) {
      <span class="spinner-border spinner-border-sm me-2" aria-hidden="true"></span>
    } @else {
      <i class="bi bi-exclamation-triangle-fill me-1"></i>
    }
    {{ activando() ? 'Activando…' : 'Alerta de barrio' }}
  </button>`,
})
export class AlertaBoton {
  private readonly paneles = inject(PanelesService);
  private readonly avisos = inject(NotificacionesService);
  readonly activada = output<void>();
  protected readonly activando = signal(false);

  protected async activar(): Promise<void> {
    if (this.activando()) return;
    const ok = await this.avisos.confirmar(
      '¿Activar alerta en tu barrio?',
      'Tu barrio quedará EN ALERTA durante 30 minutos para todos.\n\n⚠️ ¡Atención! La emisión de falsas alarmas conlleva sanciones (+1 Strike) y el bloqueo permanente del DNI (3 strikes = Ban definitivo).',
      'Activar alerta',
      true,
    );
    if (!ok) return;
    this.activando.set(true);
    try {
      await this.paneles.activarAlerta();
      this.avisos.exito('Alerta activada por 30 minutos.');
      this.activada.emit();
    } catch (error) {
      await this.avisos.error(error);
    } finally {
      this.activando.set(false);
    }
  }
}
