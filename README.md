# Nextcloud + Talk (HPB) em Docker, atras do Nginx Proxy Manager

Stack para chamadas do Talk com muitos participantes (10+), usando o
High-Performance Backend (signaling + Janus + NATS + TURN) da imagem `aio-talk`.

## Arquivos

| Arquivo | Funcao |
|---|---|
| `docker-compose.yml` | Stack: Postgres, Redis, Nextcloud, cron e Talk HPB |
| `.env.example` | Modelo das variaveis (copie/cadastre no Dockhand) |
| `setup-talk.sh` | Configura signaling, TURN e STUN via `occ` |
| `npm-custom-location.conf` | Bloco do custom location `/standalone-signaling/` no NPM |
| `npm-advanced.conf` | Bloco da aba Advanced do Proxy Host no NPM |

## Deploy no Dockhand

1. Suba este repositorio no seu Git.
2. No Dockhand, crie uma stack a partir do repositorio Git apontando para `docker-compose.yml`.
3. Cadastre as variaveis de `.env.example` nas variaveis de ambiente da stack.
   Gere cada segredo com `openssl rand -hex 32`.
4. Confirme que `NPM_NETWORK` e o nome real da rede do NPM (`docker network ls`).
5. Faca o deploy e aguarde o `nextcloud-app` ficar saudavel (a primeira instalacao demora).

## Nginx Proxy Manager

Crie o Proxy Host:

- Domain: o valor de `NC_DOMAIN`
- Forward: `http` -> `nextcloud-app` : `80`
- Ative **Block Common Exploits** e **Websockets Support**
- SSL: Let's Encrypt, com **Force SSL** e **HTTP/2**
- Custom location `/standalone-signaling/`: veja `npm-custom-location.conf`
- Aba Advanced: veja `npm-advanced.conf`

## Rede e firewall

- Encaminhe **3478 TCP e UDP** do roteador para o host do Docker (nao passa pelo NPM).
- O TURN tambem usa uma faixa de portas UDP de relay. Confira na documentacao da imagem
  `aio-talk` (repositorio `nextcloud/all-in-one`) qual faixa ela usa e libere no firewall.
- Se o container `talk` nao alcancar o dominio publico (hairpin NAT), descomente `extra_hosts`
  no `docker-compose.yml` e preencha `NPM_HOST_IP`.

## Configurar o Talk

Depois que o Nextcloud terminar de instalar, no host do Docker:

```bash
set -a; . ./.env; set +a
bash setup-talk.sh
```

Se preferir, rode os comandos `occ` do script manualmente no terminal do container
`nextcloud-app` pelo Dockhand. Os mesmos valores tambem podem ser colocados em
**Administracao > Talk**.

## Testar

1. Em **Administracao > Talk**, o High-performance backend deve aparecer sem erro.
2. Numa chamada, abra `chrome://webrtc-internals` e veja candidatos `relay`/`srflx`
   do IP do servidor, e nao conexoes P2P entre clientes.
3. Teste com poucas pessoas antes de chamadas grandes.

## Dimensionamento

O gargalo e a banda de upload do servidor e a CPU. Para 15-20 pessoas com video,
planeje 100+ Mbps simetricos e alguns cores livres.

## Backup

Guarde os volumes `db` e `nextcloud` e as variaveis da stack (segredos).
