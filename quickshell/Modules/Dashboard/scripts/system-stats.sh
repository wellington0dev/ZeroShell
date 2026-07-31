#!/usr/bin/env bash
#
# Mede uso de CPU/RAM/armazenamento (%), temperatura do processador (°C) e
# throughput de rede (KB/s down/up), e imprime tudo numa linha só:
# "cpu ram storage temp rx_kbps tx_kbps" (seis inteiros, separados por
# espaço). CPU e rede precisam de duas leituras com um intervalo entre elas
# (não dá pra saber taxa/uso instantâneo com uma leitura só) - por isso essa
# chamada demora ~0.3s de propósito; a amostra de rede aproveita o MESMO
# intervalo do sleep da CPU, não dorme de novo.

set -euo pipefail

# Interface de rede "ativa" - a que o sistema usaria pra sair pra internet
# agora (rota padrão). Se não tiver rota nenhuma (sem rede), fica vazio e as
# leituras de rx/tx abaixo simplesmente saem 0.
net_iface="$(ip -j route get 1.1.1.1 2>/dev/null | jq -r '.[0].dev // empty' 2>/dev/null || true)"

# Bytes recebidos/enviados de uma interface, lidos de /proc/net/dev (campos
# 2 e 10 da linha, depois do nome da interface com ":"). "0 0" se a
# interface não existir (mudou de rede no meio, por exemplo).
net_bytes() {
    if [ -z "$net_iface" ]; then
        echo "0 0"
        return
    fi
    awk -v iface="$net_iface:" '$1 == iface { print $2, $10 }' /proc/net/dev
}

read -r _ u1 n1 s1 i1 w1 irq1 sirq1 _ < /proc/stat
read -r rx1 tx1 < <(net_bytes)
sleep 0.3
read -r _ u2 n2 s2 i2 w2 irq2 sirq2 _ < /proc/stat
read -r rx2 tx2 < <(net_bytes)

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

# Temperatura do pacote da CPU - "x86_pkg_temp" é a leitura mais
# representativa num laptop Intel (as outras zonas térmicas do sistema, tipo
# "acpitz"/chipset, oscilam menos e representam menos o processador em si).
# Cai pra qualquer zona disponível se essa não existir (ex.: CPU AMD, sem
# "x86_pkg_temp").
temp=0
for zone in /sys/class/thermal/thermal_zone*; do
    if [ "$(cat "$zone/type" 2>/dev/null)" = "x86_pkg_temp" ]; then
        temp=$(( $(cat "$zone/temp") / 1000 ))
        break
    fi
done
if [ "$temp" -eq 0 ]; then
    first_zone="/sys/class/thermal/thermal_zone0/temp"
    [ -r "$first_zone" ] && temp=$(( $(cat "$first_zone") / 1000 ))
fi

# KB/s = bytes no intervalo / 1024 / 0.3s, em inteiro (*10/3 aproxima /0.3).
rx_kbps=$(( (rx2 - rx1) * 10 / 3 / 1024 ))
tx_kbps=$(( (tx2 - tx1) * 10 / 3 / 1024 ))

echo "$cpu $ram $storage $temp $rx_kbps $tx_kbps"
