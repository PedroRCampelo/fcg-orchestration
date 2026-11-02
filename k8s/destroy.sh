#!/usr/bin/env bash
# Remove a aplicacao do cluster apagando o namespace fcg. Os volumes (PVCs) vao junto: os dados do
# PostgreSQL e as mensagens do RabbitMQ sao perdidos.
set -euo pipefail
kubectl delete namespace fcg --ignore-not-found
