#!/usr/bin/env python3
#
# Confere a senha do usuário via PAM - usado pela lockscreen do quickshell
# (Modules/Lock/LockScreen.qml). A senha é lida do STDIN, nunca de argv (que
# ficaria visível pra qualquer processo local via "ps aux"). Depende do
# pacote "python-pam" (repo oficial do Arch).
#
# Exit 0 = senha certa. Qualquer outra coisa = errada/erro.
#
# Usage:
#   echo "senha" | lock-auth.py <username>

import sys

try:
    import pam
except ImportError:
    print("python-pam não está instalado (sudo pacman -S python-pam)", file=sys.stderr)
    sys.exit(2)

if len(sys.argv) != 2:
    print("uso: lock-auth.py <username>", file=sys.stderr)
    sys.exit(2)

username = sys.argv[1]
password = sys.stdin.readline().rstrip("\n")

ok = pam.pam().authenticate(username, password, service="login")
sys.exit(0 if ok else 1)
