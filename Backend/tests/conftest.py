"""Configuración común de pytest.

Los tests usan un Argon2id reducido para no tardar minutos. La aplicación real usa
los parámetros por defecto de argon2-cffi; este interruptor solo afecta a pytest.
"""

import os

os.environ["RADAR_ARGON2_RAPIDO"] = "1"
