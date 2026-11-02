#!/usr/bin/env bash
# Expoe no localhost os servicos do cluster, nas mesmas portas do docker compose:
# users 5101, catalog 5102, payments 5103, notifications 5104 e o painel do RabbitMQ em 15672.
# Se o RabbitMQ do docker compose estiver de pe, ele ja ocupa a 15672 (e o compose inteiro ocupa as
# 5101 a 5104): pare o compose antes, ou use RABBITMQ_MANAGEMENT_PORT=15673 para o painel.
# Ctrl+C encerra todos os redirecionamentos.
set -euo pipefail

# `kubectl port-forward svc/...` fica preso a UM pod e morre quando ele e trocado (todo rollout faz isso).
# Por isso cada redirecionamento roda em laco e se refaz sozinho, ja apontando para o pod novo.
encaminhar() {
  while true; do
    kubectl port-forward --namespace fcg "svc/$1" "$2:$3" >/dev/null 2>&1 || true
    sleep 1
  done
}

trap 'kill 0' EXIT
encaminhar users-api 5101 8080 &
encaminhar catalog-api 5102 8080 &
encaminhar payments-api 5103 8080 &
encaminhar notifications-api 5104 8080 &
encaminhar rabbitmq "${RABBITMQ_MANAGEMENT_PORT:-15672}" 15672 &
echo "redirecionando: users 5101, catalog 5102, payments 5103, notifications 5104, rabbitmq ${RABBITMQ_MANAGEMENT_PORT:-15672} (Ctrl+C para encerrar)"
wait
