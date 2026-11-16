# Nextcloud + Talk (HPB) em Docker, atras do Nginx Proxy Manager

Stack para chamadas do Talk com muitos participantes (10+), usando o
High-Performance Backend (signaling + Janus + NATS + TURN) da imagem `aio-talk`.
Nao depende de rede Docker compartilhada com o NPM: tudo e acessado por portas do host.

## Arquivos

| Arquivo | Funcao |
|---|---|
| `docker-compose.yml` | Stack: Postgres, Redis, Nextcloud, cron e Talk HPB |
| `.env.example` | Modelo das variaveis (cadastre no Dockhand) |
| `setup-talk.sh` | Configura signaling, TURN e STUN via `occ` (opcional, veja abaixo) |
| `npm-custom-location.conf` | Bloco do custom location `/standalone-signaling/` no NPM |
| `npm-advanced.conf` | Bloco da aba Advanced do Proxy Host no NPM |

## Deploy no Dockhand

1. Suba este repositorio no seu Git.
2. No Dockhand, crie uma stack a partir do repositorio apontando para `docker-compose.yml`.
3. Cadastre as variaveis de `.env.example` nas variaveis de ambiente da stack.
4. Faca o deploy e aguarde o `nextcloud-app` terminar a primeira instalacao (alguns minutos).

## Nginx Proxy Manager

Crie o Proxy Host:

- Domain: o valor de `NC_DOMAIN`
- Forward: `http` -> **IP do servidor Docker** : `8080` (`APP_PORT`). Use o IP da rede local, nao `localhost`.
- Ative **Block Common Exploits** e **Websockets Support**
- SSL: Let's Encrypt, com **Force SSL** e **HTTP/2**
- Custom location `/standalone-signaling/`: veja `npm-custom-location.conf`
- Aba Advanced: veja `npm-advanced.conf`

## Rede e firewall

- Encaminhe **3478 TCP e UDP** do roteador para o host do Docker (nao passa pelo NPM).
- O TURN tambem usa uma faixa de portas UDP de relay. Confira na documentacao da imagem
  `aio-talk` (repositorio `nextcloud/all-in-one`) qual faixa ela usa e libere no firewall.
- Nao exponha `APP_PORT` e `SIGNALING_PORT` na internet; use-as apenas na rede local
  (o acesso externo deve passar pelo NPM com HTTPS).

## Configurar o Talk

Depois que o Nextcloud terminar de instalar, configure o Talk de um destes jeitos.

**Pela interface (sem terminal):** entre como admin em **Administracao > Talk** e preencha:

- STUN: `cloud.exemplo.com:3478`
- TURN: `cloud.exemplo.com:3478`, segredo = `TURN_SECRET`, protocolos UDP e TCP
- High-performance backend: `https://cloud.exemplo.com/standalone-signaling/`, segredo = `SIGNALING_SECRET`
  (marque a verificacao de certificado se o dominio usar HTTPS valido)

Se o app Talk nao estiver instalado, instale-o em **Aplicativos**.

**Pelo terminal do host:**

```bash
set -a; . ./.env; set +a
bash setup-talk.sh
```

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
