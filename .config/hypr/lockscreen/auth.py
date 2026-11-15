"""Verifica la contraseña del usuario actual con PAM.

Lee la contraseña desde stdin (una línea). Códigos de salida:
  0  contraseña correcta
  1  contraseña incorrecta
  2  error (PAM falló de otra forma)

Llama a libpam directamente y solo hace `pam_authenticate`, que es lo mismo que
hace hyprlock. python-pam ejecuta además `pam_acct_mgmt`, y el servicio
`hyprlock` de PAM solo define la fase `auth`: la fase `account` cae en
`/etc/pam.d/other`, que deniega siempre. Con python-pam una contraseña correcta
salía rechazada.
"""

import ctypes
import ctypes.util
import os
import pwd
import sys
from ctypes import CFUNCTYPE, POINTER, Structure, c_char_p, c_int, c_size_t, c_void_p, cast, sizeof

PAM_SERVICE = "hyprlock"

PAM_SUCCESS = 0
PAM_PROMPT_ECHO_OFF = 1
PAM_PROMPT_ECHO_ON = 2
# PAM_AUTH_ERR, PAM_USER_UNKNOWN, PAM_MAXTRIES, PAM_PERM_DENIED
REJECTED = {7, 10, 11, 6}


class PamMessage(Structure):
    _fields_ = [("msg_style", c_int), ("msg", c_char_p)]


class PamResponse(Structure):
    # `resp` va como puntero crudo: lo libera PAM, no Python.
    _fields_ = [("resp", c_void_p), ("resp_retcode", c_int)]


Conversation = CFUNCTYPE(c_int, c_int, POINTER(POINTER(PamMessage)), POINTER(POINTER(PamResponse)), c_void_p)


class PamConv(Structure):
    _fields_ = [("conv", Conversation), ("appdata_ptr", c_void_p)]


def check(user: str, password: str) -> int:
    libpam = ctypes.CDLL(ctypes.util.find_library("pam"))
    libc = ctypes.CDLL(ctypes.util.find_library("c"))
    libc.calloc.restype = c_void_p
    libc.calloc.argtypes = [c_size_t, c_size_t]
    libc.strdup.restype = c_void_p
    libc.strdup.argtypes = [c_char_p]
    libpam.pam_start.restype = c_int
    libpam.pam_start.argtypes = [c_char_p, c_char_p, POINTER(PamConv), POINTER(c_void_p)]
    libpam.pam_authenticate.restype = c_int
    libpam.pam_authenticate.argtypes = [c_void_p, c_int]
    libpam.pam_end.restype = c_int
    libpam.pam_end.argtypes = [c_void_p, c_int]

    secret = password.encode()

    @Conversation
    def answer(count, messages, responses, _appdata):
        block = libc.calloc(count, sizeof(PamResponse))
        if not block:
            return 5  # PAM_BUF_ERR
        replies = cast(block, POINTER(PamResponse))
        for index in range(count):
            if messages[index].contents.msg_style in (PAM_PROMPT_ECHO_OFF, PAM_PROMPT_ECHO_ON):
                replies[index].resp = libc.strdup(secret)
        responses[0] = replies
        return PAM_SUCCESS

    conversation = PamConv(answer, None)
    handle = c_void_p()
    started = libpam.pam_start(PAM_SERVICE.encode(), user.encode(), ctypes.byref(conversation), ctypes.byref(handle))
    if started != PAM_SUCCESS:
        print(f"auth.py: pam_start falló (código {started})", file=sys.stderr)
        return 2
    result = libpam.pam_authenticate(handle, 0)
    libpam.pam_end(handle, result)
    if result == PAM_SUCCESS:
        return 0
    if result in REJECTED:
        print(f"auth.py: PAM rechazó la contraseña (código {result})", file=sys.stderr)
        return 1
    print(f"auth.py: pam_authenticate falló (código {result})", file=sys.stderr)
    return 2


def main() -> int:
    password = sys.stdin.readline()
    if password.endswith("\n"):
        password = password[:-1]
    user = pwd.getpwuid(os.getuid()).pw_name
    try:
        return check(user, password)
    except Exception as error:  # noqa: BLE001 - cualquier fallo aquí es "no se pudo verificar"
        print(f"auth.py: error al hablar con PAM: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
