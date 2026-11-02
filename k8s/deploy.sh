#!/usr/bin/env bash
# Sobe a aplicacao completa no cluster Kubernetes do Docker Desktop.
# Pre-requisitos: Kubernetes habilitado no Docker Desktop, o .env com a JWT__SIGNINGKEY e as imagens
# locais construidas (`docker compose build`, na pasta pai). Os repositorios dos servicos precisam estar
# ao lado deste (../../fcg-*-api), de onde saem os manifestos de cada servico.
set -euo pipefail

AQUI="$(cd "$(dirname "$0")" && pwd)"
RAIZ="$(cd "$AQUI/../.." && pwd)"
SERVICOS=(users-api catalog-api payments-api notifications-api)
PRAZO="${PRAZO_ROLLOUT:-420s}"

echo "contexto do kubectl: $(kubectl config current-context)"
kubectl cluster-info >/dev/null

for servico in "${SERVICOS[@]}"; do
  docker image inspect "fcg-$servico:local" >/dev/null 2>&1 || {
    echo "imagem fcg-$servico:local nao existe no Docker local. Rode: docker compose build (em $AQUI/..)" >&2
    exit 1
  }
  [ -d "$RAIZ/fcg-$servico/k8s" ] || { echo "faltam os manifestos em $RAIZ/fcg-$servico/k8s" >&2; exit 1; }
done

kubectl apply -f "$AQUI/00-namespace.yaml"
"$AQUI/create-jwt-secret.sh"

# Infra primeiro e pronta antes dos servicos: eles esperam o banco e o broker na subida, mas assim a
# primeira implantacao nao passa por reinicios desnecessarios.
kubectl apply -f "$AQUI/postgres.yaml" -f "$AQUI/rabbitmq.yaml"
kubectl rollout status statefulset/postgres --namespace fcg --timeout="$PRAZO"
kubectl rollout status statefulset/rabbitmq --namespace fcg --timeout="$PRAZO"

for servico in "${SERVICOS[@]}"; do
  kubectl apply -f "$RAIZ/fcg-$servico/k8s"
done
for servico in "${SERVICOS[@]}"; do
  kubectl rollout status deployment/"$servico" --namespace fcg --timeout="$PRAZO"
done

kubectl get pods --namespace fcg
