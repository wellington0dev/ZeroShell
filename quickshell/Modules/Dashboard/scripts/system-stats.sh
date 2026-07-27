#!/usr/bin/env bash
#
# Mede uso de CPU/RAM/armazenamento (%) e imprime "cpu ram storage" (três
# inteiros, separados por espaço) na saída padrão. CPU precisa de duas
# leituras de /proc/stat com um intervalo entre elas (não dá pra saber uso
# instantâneo com uma leitura só) - por isso essa chamada demora ~0.3s de
# propósito.

set -euo pipefail

read -r _ u1 n1 s1 i1 w1 irq1 sirq1 _ < /proc/stat
sleep 0.3
read -r _ u2 n2 s2 i2 w2 irq2 sirq2 _ < /proc/stat

idle1=$((i1 + w1))
idle2=$((i2 + w2))
total1=$((u1 + n1 + s1 + i1 + w1 + irq1 + sirq1))
total2=$((u2 + n2 + s2 + i2 + w2 + irq2 + sirq2))

totald=$((total2 - total1))
idled=$((idle2 - idle1))

cpu=0
if [ "$totald" -gt 0 ]; then
    cpu=$(( (1000 * (totald - idled) / totald + 5) / 10 ))
fi

ram=$(awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{printf "%d", (t-a)*100/t}' /proc/meminfo)

storage=$(df --output=pcent "$HOME" | tail -1 | tr -dc '0-9')

echo "$cpu $ram $storage"
