#!/usr/bin/env bash
# Configura o Talk (HPB, TURN e STUN) no Nextcloud ja em execucao.
# Uso:  set -a; . ./.env; set +a; bash setup-talk.sh
# (ou exporte NC_DOMAIN, SIGNALING_SECRET e TURN_SECRET manualmente)
set -euo pipefail

: "${NC_DOMAIN:?defina NC_DOMAIN}"
: "${SIGNALING_SECRET:?defina SIGNALING_SECRET}"
: "${TURN_SECRET:?defina TURN_SECRET}"

OCC="docker exec -u www-data nextcloud-app php occ"

echo ">> Aguardando o Nextcloud terminar a instalacao..."
until $OCC status 2>/dev/null | grep -q "installed: true"; do
  sleep 5
done

echo ">> Instalando/ativando o app Talk (spreed)..."
$OCC app:install spreed 2>/dev/null || $OCC app:enable spreed

echo ">> Limpando configuracoes antigas de signaling/TURN/STUN..."
$OCC talk:signaling:delete 0 2>/dev/null || true
$OCC talk:turn:delete turn "${NC_DOMAIN}:3478" udp,tcp 2>/dev/null || true
$OCC talk:stun:delete "${NC_DOMAIN}:3478" 2>/dev/null || true

echo ">> Configurando signaling (HPB)..."
$OCC talk:signaling:add "https://${NC_DOMAIN}/standalone-signaling/" "${SIGNALING_SECRET}" --verify

echo ">> Configurando TURN e STUN..."
$OCC talk:turn:add turn "${NC_DOMAIN}:3478" udp,tcp --secret="${TURN_SECRET}"
$OCC talk:stun:add "${NC_DOMAIN}:3478"

echo ">> Configuracao atual:"
$OCC talk:signaling:list
$OCC talk:turn:list
$OCC talk:stun:list

echo ">> Pronto."
