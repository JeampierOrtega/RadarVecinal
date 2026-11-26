from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator

# Solo dos actores en el sistema.
Rol = Literal["vecino", "municipalidad"]
EstadoUsuario = Literal["Pendiente", "Verificado", "Rechazado", "Suspendido", "Baneado"]

CORREO_PATTERN = r"^[^@\s]+@[^@\s]+\.[^@\s]+$"
DNI_PATTERN = r"^[0-9]{8}$"

# Requisitos de las contraseñas nuevas. El login no los aplica: las cuentas demo
# conservan su clave corta y Argon2 la sigue validando con normalidad.
CLAVE_MINIMA = 8
CLAVE_MAXIMA = 50
SIMBOLOS_CLAVE = set('!@#$%^&*(),.?":{}|<>_-')


class Login(BaseModel):
    """Credenciales para iniciar sesión."""

    model_config = ConfigDict(str_strip_whitespace=True)

    correo: str = Field(..., pattern=CORREO_PATTERN, examples=["vecino@barrio.com"])
    clave: str = Field(..., min_length=1, examples=["123456"])


class UsuarioRegistro(BaseModel):
    """Datos para que un vecino cree su cuenta."""

    model_config = ConfigDict(str_strip_whitespace=True)

    nombre: str = Field(..., min_length=3, max_length=100, examples=["Rosa Quispe"])
    dni: str = Field(..., pattern=DNI_PATTERN, min_length=8, max_length=8, examples=["40000001"])
    correo: str = Field(..., pattern=CORREO_PATTERN, examples=["rosa@correo.com"])
    clave: str = Field(
        ...,
        description="Mínimo 8 caracteres, con mayúscula, número y símbolo.",
        examples=["Radar2026!"],
    )
    id_barrio: str = Field(..., min_length=1, examples=["b1"])
    codigo_barrio: str = Field(..., min_length=1, examples=["TORRE-2026"])

    @field_validator("clave")
    @classmethod
    def validar_clave_segura(cls, clave: str) -> str:
        """Mismos cuatro criterios que el medidor del frontend."""
        if len(clave) < CLAVE_MINIMA or len(clave) > CLAVE_MAXIMA:
            raise ValueError(
                f"La contraseña debe tener entre {CLAVE_MINIMA} y {CLAVE_MAXIMA} caracteres."
            )
        if not any("A" <= caracter <= "Z" for caracter in clave):
            raise ValueError("La contraseña debe incluir al menos una letra mayúscula (A-Z).")
        if not any("0" <= caracter <= "9" for caracter in clave):
            raise ValueError("La contraseña debe incluir al menos un número (0-9).")
        if not any(caracter in SIMBOLOS_CLAVE for caracter in clave):
            raise ValueError(
                'La contraseña debe incluir al menos un símbolo (!@#$%^&*(),.?":{}|<>_-).'
            )
        return clave


class UsuarioUpdate(BaseModel):
    """Datos modificables de un usuario (el correo y el rol no cambian)."""

    model_config = ConfigDict(str_strip_whitespace=True)

    nombre: str = Field(..., min_length=3, max_length=100)
    id_barrio: str = Field(..., min_length=1)


class Verificacion(BaseModel):
    """Decisión de la Municipalidad sobre un vecino pendiente."""

    decision: Literal["aprobar", "rechazar"]


class ModerarUsuarioRequest(BaseModel):
    """Acciones de moderación que aplica la Municipalidad a un vecino."""

    accion: Literal["suspender", "banear", "reactivar"]
    dias: int | None = None  # 1, 7 o 30
    motivo: str | None = None


class Usuario(BaseModel):
    """Usuario tal como se devuelve al frontend (sin contraseña)."""

    id: str
    nombre: str
    dni: str | None = None
    correo: str
    rol: Rol
    id_barrio: str | None
    estado: EstadoUsuario
    fecha_registro: datetime
    institucion: str | None = None
    strikes: int = 0
    suspendido_hasta: datetime | None = None
    motivo_sancion: str | None = None


class UsuarioDB(Usuario):
    """Usuario almacenado: incluye el hash de la contraseña (nunca sale por la API)."""

    clave_hash: str
