import { Component, OnInit, inject, signal } from '@angular/core';
import {
  FormField,
  email,
  form,
  maxLength,
  minLength,
  required,
  submit,
  validate,
} from '@angular/forms/signals';
import { Router, RouterLink } from '@angular/router';

import { Barrio } from '../../Interfaces/barrio.interface';
import { mensajeDeError } from '../../Services/api.service';
import { AuthService } from '../../Services/auth.service';
import { NotificacionesService } from '../../Services/notificaciones.service';
import { ZonasService } from '../../Services/zonas.service';

@Component({
  selector: 'app-registro',
  imports: [FormField, RouterLink],
  templateUrl: './registro.html',
  styleUrl: './registro.css',
})
export class Registro implements OnInit {
  private readonly auth = inject(AuthService);
  private readonly zonasService = inject(ZonasService);
  private readonly router = inject(Router);
  private readonly avisos = inject(NotificacionesService);

  protected readonly barrios = signal<Barrio[]>([]);
  protected readonly cargando = signal(false);
  protected readonly cargandoBarrios = signal(true);
  protected readonly errorBarrios = signal('');

  protected readonly modelo = signal({
    nombre: '',
    dni: '',
    correo: '',
    clave: '',
    id_barrio: '',
    codigo_barrio: '',
  });

  protected readonly formulario = form(this.modelo, (campos) => {
    required(campos.nombre, { message: 'Escribe tu nombre completo.' });
    minLength(campos.nombre, 3, { message: 'El nombre debe tener al menos 3 letras.' });
    required(campos.dni, { message: 'Ingresa tu número de DNI.' });
    maxLength(campos.dni, 8, { message: 'El DNI debe tener 8 dígitos.' });
    validate(campos.dni, ({ value }) => {
      const v = value().trim();
      if (!v) return undefined;
      return /^\d{8}$/.test(v)
        ? undefined
        : { kind: 'dni', message: 'El DNI debe tener exactamente 8 dígitos numéricos.' };
    });
    required(campos.correo, { message: 'Escribe tu correo.' });
    email(campos.correo, { message: 'El correo no es válido.' });
    required(campos.clave, { message: 'Crea una contraseña.' });
    minLength(campos.clave, 6, { message: 'La contraseña debe tener al menos 6 caracteres.' });
    required(campos.id_barrio, { message: 'Elige tu barrio.' });
    validate(campos.codigo_barrio, ({ value }) => {
      if (this.modelo().id_barrio && !value().trim()) {
        return { kind: 'required', message: 'Ingresa el código de acceso de tu barrio.' };
      }
      return undefined;
    });
  });

  async ngOnInit(): Promise<void> {
    await this.cargarBarrios();
  }

  protected soloDigitos(evento: KeyboardEvent): void {
    const input = evento.target as HTMLInputElement;
    if (
      !/^\d$/.test(evento.key) &&
      !['Backspace', 'Delete', 'ArrowLeft', 'ArrowRight', 'Tab'].includes(evento.key)
    ) {
      evento.preventDefault();
      return;
    }
    if (
      /^\d$/.test(evento.key) &&
      input.value.length >= 8 &&
      input.selectionStart === input.selectionEnd
    ) {
      evento.preventDefault();
    }
  }

  protected limpiarDni(evento: Event): void {
    const input = evento.target as HTMLInputElement;
    const valorLimpio = input.value.replace(/\D/g, '').slice(0, 8);
    if (input.value !== valorLimpio) {
      input.value = valorLimpio;
      this.modelo.update((m) => ({ ...m, dni: valorLimpio }));
    }
  }

  protected async cargarBarrios(): Promise<void> {
    this.cargandoBarrios.set(true);
    this.errorBarrios.set('');
    try {
      this.barrios.set(await this.zonasService.barrios());
    } catch (error) {
      this.errorBarrios.set(mensajeDeError(error));
    } finally {
      this.cargandoBarrios.set(false);
    }
  }

  protected async enviar(evento: Event): Promise<void> {
    evento.preventDefault();
    await submit(this.formulario, async () => {
      this.cargando.set(true);
      try {
        const usuario = await this.auth.registrar(this.modelo());
        this.avisos.exito('¡Cuenta verificada y creada con éxito! Bienvenido a Radar Vecinal.');
        await this.router.navigateByUrl(this.auth.rutaInicial(usuario));
      } catch (error) {
        await this.avisos.error(error);
      } finally {
        this.cargando.set(false);
      }
    });
  }
}
