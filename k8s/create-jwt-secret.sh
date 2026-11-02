#!/usr/bin/env bash
# Cria (ou atualiza) o Secret `jwt-signing-key`, unico consumidor da chave de assinatura do JWT:
# o mesmo Secret e lido por users-api, catalog-api e payments-api. A chave vem de JWT__SIGNINGKEY,
# do ambiente ou do .env desta pasta pai, e nunca e escrita em arquivo nem impressa.
set -euo pipefail

AQUI="$(cd "$(dirname "$0")" && pwd)"
ARQUIVO_ENV="$AQUI/../.env"

if [ -z "${JWT__SIGNINGKEY:-}" ] && [ -f "$ARQUIVO_ENV" ]; then
  JWT__SIGNINGKEY="$(grep -E '^JWT__SIGNINGKEY=' "$ARQUIVO_ENV" | head -n 1 | cut -d= -f2-)"
fi

if [ "${#JWT__SIGNINGKEY}" -lt 32 ]; then
  echo "JWT__SIGNINGKEY ausente ou com menos de 32 caracteres. Defina no .env (veja o .env.example)." >&2
  exit 1
fi

kubectl get namespace fcg >/dev/null 2>&1 || kubectl apply -f "$AQUI/00-namespace.yaml"

kubectl create secret generic jwt-signing-key --namespace fcg \
  --from-literal=JWT__SIGNINGKEY="$JWT__SIGNINGKEY" \
  --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl label secret jwt-signing-key --namespace fcg app.kubernetes.io/part-of=fcg --overwrite >/dev/null

echo "secret/jwt-signing-key aplicado no namespace fcg (${#JWT__SIGNINGKEY} caracteres)"
