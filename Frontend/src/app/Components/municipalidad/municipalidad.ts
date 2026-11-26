import { DatePipe } from '@angular/common';
import { Component, OnInit, computed, inject, signal } from '@angular/core';
import Swal from 'sweetalert2';

import { Accion, EstadoAccion } from '../../Interfaces/accion.interface';
import { ESTADOS_ACCION, ETIQUETA_NIVEL, ETIQUETA_TIPO } from '../../Interfaces/constantes';
import { Alerta, PanelMunicipal } from '../../Interfaces/panel.interface';
import { ReportePublico } from '../../Interfaces/reporte.interface';
import { Usuario } from '../../Interfaces/usuario.interface';
import { AccionesService } from '../../Services/acciones.service';
import { mensajeDeError } from '../../Services/api.service';
import { NotificacionesService } from '../../Services/notificaciones.service';
import { PanelesService } from '../../Services/paneles.service';
import { ReportesService } from '../../Services/reportes.service';
import { UsuariosService } from '../../Services/usuarios.service';
import { AccionFormulario } from '../accion-formulario/accion-formulario';
import { Cargando } from '../cargando/cargando';
import { ErrorCarga } from '../error-carga/error-carga';
import { Estadisticas } from '../estadisticas/estadisticas';
import { Modal } from '../modal/modal';
import { ReporteDetalle } from '../reporte-detalle/reporte-detalle';

type Pestana = 'criticos' | 'acciones' | 'vecinos' | 'reportes' | 'estadisticas';

/** Pantalla del actor Municipalidad: alertas en vivo, moderación de reportes y vecinos. */
@Component({
  selector: 'app-municipalidad',
  imports: [DatePipe, AccionFormulario, Estadisticas, Modal, ReporteDetalle, Cargando, ErrorCarga],
  templateUrl: './municipalidad.html',
  styleUrl: './municipalidad.css',
})
export class Municipalidad implements OnInit {
  private readonly paneles = inject(PanelesService);
  private readonly reportesService = inject(ReportesService);
  private readonly acciones = inject(AccionesService);
  private readonly usuarios = inject(UsuariosService);
  private readonly avisos = inject(NotificacionesService);

  protected readonly panel = signal<PanelMunicipal | null>(null);
  protected readonly cargando = signal(true);
  protected readonly errorCarga = signal('');
  protected readonly pestana = signal<Pestana>('criticos');
  protected readonly barrioElegido = signal('');
  protected readonly editando = signal<Accion | null>(null);
  protected readonly reporteId = signal<string | null>(null);
  protected readonly reporteRespondido = signal<ReportePublico | null>(null);
  protected readonly cambiandoEstado = signal<string | null>(null);
  protected readonly procesandoAccion = signal<string | null>(null);

  protected readonly estados = ESTADOS_ACCION;
  protected readonly etiquetaNivel = ETIQUETA_NIVEL;
  protected readonly etiquetaTipo = ETIQUETA_TIPO;
  protected readonly pestanas: { id: Pestana; texto: string; icono: string }[] = [
    { id: 'criticos', texto: 'Barrios críticos', icono: 'bi-exclamation-triangle' },
    { id: 'acciones', texto: 'Acciones', icono: 'bi-clipboard-check' },
    { id: 'reportes', texto: 'Moderación de reportes', icono: 'bi-shield-exclamation' },
    { id: 'vecinos', texto: 'Moderación de vecinos', icono: 'bi-people' },
    { id: 'estadisticas', texto: 'Estadísticas', icono: 'bi-bar-chart' },
  ];

  protected readonly activas = computed(
    () => (this.panel()?.acciones ?? []).filter((a) => a.estado !== 'Completada').length,
  );
  protected readonly zonasAlerta = computed(
    () =>
      (this.panel()?.zonas ?? []).filter((z) => z.nivel === 'naranja' || z.nivel === 'rojo').length,
  );

  protected readonly alertasActivas = computed<Alerta[]>(() => this.panel()?.alertas ?? []);
  protected readonly vecinosLista = computed<Usuario[]>(() => this.panel()?.vecinos ?? []);

  /** Los reportes con denuncias o incorrectos van primero: son los que necesitan revisión urgente. */
  protected readonly reportesOrdenados = computed(() =>
    [...(this.panel()?.reportes ?? [])].sort((a, b) => {
      const sospechosoA = a.denuncias > 0 || (a.incorrectos ?? 0) > 0 ? 1 : 0;
      const sospechosoB = b.denuncias > 0 || (b.incorrectos ?? 0) > 0 ? 1 : 0;
      if (sospechosoB !== sospechosoA) return sospechosoB - sospechosoA;
      const puntosB = b.denuncias + (b.incorrectos ?? 0);
      const puntosA = a.denuncias + (a.incorrectos ?? 0);
      if (puntosB !== puntosA) return puntosB - puntosA;
      return Date.parse(b.fecha) - Date.parse(a.fecha);
    }),
  );

  protected readonly denunciados = computed(
    () => this.reportesOrdenados().filter((r) => r.denuncias > 0 || (r.incorrectos ?? 0) > 0).length,
  );

  protected readonly vecinosSancionados = computed(
    () =>
      this.vecinosLista().filter(
        (u) => u.estado === 'Suspendido' || u.estado === 'Baneado' || u.strikes > 0,
      ).length,
  );

  /** Acción oficial que ya responde a un reporte (si existe). */
  protected respuestaDe(idReporte: string): Accion | undefined {
    return this.panel()?.acciones.find((a) => a.id_reporte === idReporte);
  }

  async ngOnInit(): Promise<void> {
    await this.cargar();
  }

  protected async cargar(mostrarCarga = true): Promise<void> {
    if (mostrarCarga) this.cargando.set(true);
    this.errorCarga.set('');
    try {
      this.panel.set(await this.paneles.panelMunicipal());
    } catch (error) {
      this.errorCarga.set(mensajeDeError(error));
    } finally {
      if (mostrarCarga) this.cargando.set(false);
    }
  }

  protected nombreBarrio(id: string): string {
    return this.panel()?.zonas.find((z) => z.id === id)?.nombre ?? id;
  }

  protected anchoTemperatura(temperatura: number): number {
    return Math.min(100, Math.max(4, (temperatura / 45) * 100));
  }

  protected responder(idBarrio: string): void {
    this.barrioElegido.set(idBarrio);
    this.pestana.set('acciones');
  }

  protected async accionGuardada(): Promise<void> {
    this.editando.set(null);
    await this.cargar(false);
  }

  /** Abre el formulario de acción como respuesta oficial a un reporte. */
  protected responderReporte(reporte: ReportePublico): void {
    this.reporteId.set(null);
    this.reporteRespondido.set(reporte);
  }

  protected responderReportePorId(id: string): void {
    const reporte = this.reportesOrdenados().find((r) => r.id === id);
    if (reporte) this.responderReporte(reporte);
  }

  protected async respuestaGuardada(): Promise<void> {
    this.reporteRespondido.set(null);
    this.avisos.exito('Respuesta publicada: el vecino ya puede verla en su reporte.');
    await this.cargar(false);
  }

  protected async cambiarEstado(accion: Accion, evento: Event): Promise<void> {
    const select = evento.target as HTMLSelectElement;
    if (this.cambiandoEstado()) {
      select.value = accion.estado;
      return;
    }
    this.cambiandoEstado.set(accion.id);
    try {
      await this.acciones.cambiarEstado(accion.id, select.value as EstadoAccion);
      this.avisos.exito('Estado actualizado. El vecino verá el cambio en su barrio.');
    } catch (error) {
      select.value = accion.estado;
      await this.avisos.error(error);
    } finally {
      this.cambiandoEstado.set(null);
    }
    await this.cargar(false);
  }

  protected async eliminarAccion(accion: Accion): Promise<void> {
    if (!(await this.avisos.confirmar('¿Eliminar esta acción?', accion.titulo, 'Eliminar', true)))
      return;
    try {
      await this.acciones.eliminar(accion.id);
      this.avisos.exito('Acción eliminada.');
      await this.cargar(false);
    } catch (error) {
      await this.avisos.error(error);
    }
  }

  // --- CONTROL DE ALERTAS EN VIVO ---
  protected async cancelarAlerta(idAlerta: string, motivo: 'atendida' | 'falsa_alarma'): Promise<void> {
    const esFalsa = motivo === 'falsa_alarma';
    const ok = await this.avisos.confirmar(
      esFalsa ? '¿Declarar falsa alarma?' : '¿Marcar alerta como atendida?',
      esFalsa
        ? 'Se cancelará la alerta y se sancionará al vecino con +1 Strike por emitir una falsa alarma.'
        : 'La alerta de pánico se retirará del mapa al haberse atendido satisfactoriamente.',
      esFalsa ? 'Falsa alarma (+1 Strike)' : 'Atendida',
      esFalsa,
    );
    if (!ok) return;

    this.procesandoAccion.set(idAlerta);
    try {
      const res = await this.paneles.cancelarAlerta(idAlerta, motivo);
      this.avisos.exito(res.detail || 'Alerta procesada.');
      await this.cargar(false);
    } catch (error) {
      await this.avisos.error(error);
    } finally {
      this.procesandoAccion.set(null);
    }
  }

  // --- MODERACIÓN DE REPORTES (ANTI-FAKE / ANTI-SPAM) ---
  protected async marcarFalso(reporte: ReportePublico): Promise<void> {
    const ok = await this.avisos.confirmar(
      '¿Marcar reporte como falso?',
      'El reporte dejará de mostrarse en el mapa y en el calor del barrio, y se aplicará +1 Strike al autor.',
      'Marcar falso (+1 Strike)',
      true,
    );
    if (!ok) return;

    this.procesandoAccion.set(reporte.id);
    try {
      const res = await this.reportesService.moderarAccion(reporte.id, 'marcar_falso');
      this.avisos.exito(res.detail || 'Reporte marcado como falso.');
      await this.cargar(false);
    } catch (error) {
      await this.avisos.error(error);
    } finally {
      this.procesandoAccion.set(null);
    }
  }

  protected async purgarSpam(reporte: ReportePublico): Promise<void> {
    const ok = await this.avisos.confirmar(
      '¿Purgar spam y banear al vecino?',
      'Se marcarán como falsos todos los reportes activos del autor y su cuenta será baneada permanentemente.',
      'Purgar spam y banear',
      true,
    );
    if (!ok) return;

    this.procesandoAccion.set(reporte.id);
    try {
      const res = await this.reportesService.moderarAccion(reporte.id, 'purgar_spam');
      this.avisos.exito(res.detail || 'Spam purgado y usuario baneado.');
      await this.cargar(false);
    } catch (error) {
      await this.avisos.error(error);
    } finally {
      this.procesandoAccion.set(null);
    }
  }

  // --- MODERACIÓN DE VECINOS ---
  protected async suspenderVecino(u: Usuario): Promise<void> {
    const { value: formValues } = await Swal.fire({
      title: `Suspender a ${u.nombre}`,
      html: `
        <div class="text-start mb-2">
          <label class="form-label fw-semibold">Duración de la suspensión:</label>
          <select id="swal-dias" class="form-select mb-3">
            <option value="1">24 horas (1 día)</option>
            <option value="7" selected>7 días (1 semana)</option>
            <option value="30">30 días (1 mes)</option>
          </select>
          <label class="form-label fw-semibold">Motivo de la sanción:</label>
          <input id="swal-motivo" class="form-control" placeholder="Ej. Reporte falso reiterado" value="Infracción a las normas vecinales">
        </div>
      `,
      focusConfirm: false,
      showCancelButton: true,
      confirmButtonText: 'Aplicar suspensión',
      confirmButtonColor: '#f58b1f',
      cancelButtonText: 'Cancelar',
      preConfirm: () => {
        const dias = Number((document.getElementById('swal-dias') as HTMLSelectElement).value);
        const motivo = (document.getElementById('swal-motivo') as HTMLInputElement).value.trim();
        if (!motivo) {
          Swal.showValidationMessage('Debes ingresar un motivo para la suspensión.');
          return false;
        }
        return { dias, motivo };
      },
    });

    if (!formValues) return;
    this.procesandoAccion.set(u.id);
    try {
      await this.usuarios.moderar(u.id, {
        accion: 'suspender',
        dias: formValues.dias,
        motivo: formValues.motivo,
      });
      this.avisos.exito(`Vecino suspendido por ${formValues.dias} días.`);
      await this.cargar(false);
    } catch (error) {
      await this.avisos.error(error);
    } finally {
      this.procesandoAccion.set(null);
    }
  }

  protected async banearVecino(u: Usuario): Promise<void> {
    const { value: motivo } = await Swal.fire({
      title: `¿Banear permanentemente a ${u.nombre}?`,
      text: 'Esta acción bloqueará de forma definitiva el acceso y el DNI de este vecino.',
      input: 'text',
      inputPlaceholder: 'Ingresa el motivo del bloqueo definitivo',
      inputValue: 'Infracciones reiteradas o spam malicioso',
      showCancelButton: true,
      confirmButtonText: 'Banear definitivamente',
      confirmButtonColor: '#d9382b',
      cancelButtonText: 'Cancelar',
      inputValidator: (value) => {
        if (!value || !value.trim()) {
          return 'Debes especificar el motivo del baneo.';
        }
        return null;
      },
    });

    if (!motivo) return;
    this.procesandoAccion.set(u.id);
    try {
      await this.usuarios.moderar(u.id, { accion: 'banear', motivo: motivo.trim() });
      this.avisos.exito('Cuenta baneada permanentemente.');
      await this.cargar(false);
    } catch (error) {
      await this.avisos.error(error);
    } finally {
      this.procesandoAccion.set(null);
    }
  }

  protected async reactivarVecino(u: Usuario): Promise<void> {
    const ok = await this.avisos.confirmar(
      `¿Reactivar cuenta de ${u.nombre}?`,
      'Se restablecerá su estado a Activo y sus strikes volverán a 0/3.',
      'Reactivar cuenta',
      false,
    );
    if (!ok) return;

    this.procesandoAccion.set(u.id);
    try {
      await this.usuarios.moderar(u.id, { accion: 'reactivar' });
      this.avisos.exito('Cuenta reactivada y strikes restablecidos.');
      await this.cargar(false);
    } catch (error) {
      await this.avisos.error(error);
    } finally {
      this.procesandoAccion.set(null);
    }
  }
}
