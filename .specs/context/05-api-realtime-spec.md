# API & Realtime Spec

## Convenções

- API REST usa JSON.
- Validação de entrada usa Zod no backend.
- Autenticação usa JWT.
- WebSocket deve autenticar no handshake.
- IDs são UUID.
- Datas usam ISO 8601 em REST e timestamp em milissegundos para movimento realtime quando necessário.
- Eventos realtime efêmeros não devem ser persistidos, exceto quando também representarem mensagens, recados ou notificações.

## REST API

### Auth

`POST /auth/register`

Entrada:

```json
{
  "displayName": "Luiz",
  "email": "luiz@example.com",
  "password": "secret"
}
```

Saída:

```json
{
  "userId": "uuid",
  "displayName": "Luiz",
  "avatarProfileId": "uuid"
}
```

`POST /auth/login`

Entrada:

```json
{
  "email": "luiz@example.com",
  "password": "secret"
}
```

Saída:

```json
{
  "accessToken": "jwt",
  "user": {},
  "organizations": [],
  "avatar": {}
}
```

Endpoints:

- `POST /auth/logout`
- `GET /auth/me`

### Organizations

- `POST /organizations`
- `GET /organizations`
- `GET /organizations/:id`
- `POST /organizations/:id/invitations`
- `POST /invitations/:token/accept`
- `GET /organizations/:id/members`
- `PATCH /organizations/:id/members/:memberId/role`

Papéis:

- `Owner`
- `Admin`
- `Member`
- `Guest`

### Workspace

- `POST /organizations/:organizationId/workspaces`
- `GET /organizations/:organizationId/workspaces`
- `GET /workspaces/:workspaceId`
- `GET /workspaces/:workspaceId/map`
- `GET /workspaces/:workspaceId/floors/:floorId`

`GET /workspaces/:workspaceId/map` deve retornar:

- Workspace.
- Floor ativo.
- Map JSON.
- Salas.
- Mesas.
- Objetos.
- Zonas interativas.
- Asset pack usado.

### Rooms

- `POST /workspaces/:workspaceId/rooms`
- `GET /workspaces/:workspaceId/rooms`
- `GET /rooms/:roomId`
- `PATCH /rooms/:roomId`
- `DELETE /rooms/:roomId`

### Desks

- `POST /workspaces/:workspaceId/desks`
- `GET /workspaces/:workspaceId/desks`
- `GET /desks/:deskId`
- `PATCH /desks/:deskId/assign`
- `POST /desks/:deskId/messages`
- `GET /desks/:deskId/messages`

### Avatar

- `GET /avatar/me`
- `PATCH /avatar/me`
- `GET /avatar/cosmetics`
- `POST /avatar/preview`

### Chat

- `GET /conversations/:conversationId/messages`
- `POST /conversations/:conversationId/messages`
- `GET /rooms/:roomId/messages`
- `GET /private/:userId/messages`

### Notifications

- `GET /notifications`
- `PATCH /notifications/:id/read`
- `PATCH /notifications/read-all`

## WebSocket Channels

Canal por escopo:

- `workspace:{workspaceId}`
- `floor:{floorId}`
- `room:{roomId}`
- `user:{userId}`

Redis Pub/Sub deve espelhar canais quando houver múltiplas instâncias.

## Client -> Server

### `workspace:join`

```json
{
  "workspaceId": "uuid",
  "floorId": "uuid"
}
```

Efeitos:

- Cria/atualiza sessão de presença.
- Entra no canal workspace/floor.
- Emite `workspace:user.joined` aos demais.

### `workspace:leave`

```json
{
  "workspaceId": "uuid"
}
```

### `avatar:move`

```json
{
  "x": 120,
  "y": 240,
  "direction": "right",
  "movementState": "walkingRight",
  "timestamp": 1710000000000
}
```

Regras:

- Backend valida limites, colisões e frequência.
- Evento pode ser rejeitado com erro se posição for inválida.
- Backend propaga `avatar:moved`.

### `avatar:stop`

```json
{
  "x": 120,
  "y": 240,
  "direction": "right",
  "movementState": "idleRight"
}
```

### `presence:status.change`

```json
{
  "status": "focus"
}
```

### `interaction:send`

```json
{
  "type": "wave",
  "targetType": "user",
  "targetId": "uuid"
}
```

### `desk:knock`

```json
{
  "deskId": "uuid"
}
```

### `desk:message.leave`

```json
{
  "deskId": "uuid",
  "content": "Passei aqui para falar sobre o projeto."
}
```

### `chat:message.send`

```json
{
  "channelType": "room",
  "roomId": "uuid",
  "content": "Pessoal, vamos começar?"
}
```

### `chat:typing.start`

```json
{
  "channelType": "room",
  "roomId": "uuid"
}
```

### `chat:typing.stop`

```json
{
  "channelType": "room",
  "roomId": "uuid"
}
```

### `room:enter`

```json
{
  "roomId": "uuid"
}
```

### `room:leave`

```json
{
  "roomId": "uuid"
}
```

### `call:invite`

```json
{
  "targetUserId": "uuid",
  "source": "desk",
  "deskId": "uuid"
}
```

### `webrtc:offer`

```json
{
  "targetUserId": "uuid",
  "sdp": "v=0\r\no=...\r\n..."
}
```

### `webrtc:answer`

```json
{
  "targetUserId": "uuid",
  "sdp": "v=0\r\no=...\r\n..."
}
```

### `webrtc:ice-candidate`

```json
{
  "targetUserId": "uuid",
  "candidate": {
    "candidate": "candidate:...",
    "sdpMid": "0",
    "sdpMLineIndex": 0
  }
}
```

### `webrtc:hangup`

```json
{
  "targetUserId": "uuid"
}
```

## Server -> Client

### `workspace:user.joined`

```json
{
  "userId": "uuid",
  "displayName": "Luiz",
  "avatar": {},
  "x": 100,
  "y": 200,
  "status": "available"
}
```

### `workspace:user.left`

```json
{
  "userId": "uuid"
}
```

### `avatar:moved`

```json
{
  "userId": "uuid",
  "x": 150,
  "y": 220,
  "direction": "down",
  "movementState": "walkingDown"
}
```

### `presence:status.changed`

```json
{
  "userId": "uuid",
  "status": "busy"
}
```

### `proximity:user.detected`

```json
{
  "nearbyUserId": "uuid",
  "distance": 2.8,
  "availableActions": ["wave", "call", "chat", "coffee", "shout"],
  "webrtcAvailable": true
}
```

### `proximity:desk.detected`

```json
{
  "deskId": "uuid",
  "ownerUserId": "uuid",
  "availableActions": ["knock", "call", "leaveMessage", "wave"]
}
```

### `proximity:lost`

```json
{
  "targetType": "desk",
  "targetId": "uuid"
}
```

### `interaction:received`

```json
{
  "interactionId": "uuid",
  "fromUserId": "uuid",
  "type": "wave",
  "payload": {}
}
```

### `bubble:show`

```json
{
  "targetType": "user",
  "targetId": "uuid",
  "bubbleType": "typing",
  "durationMs": 3000
}
```

### `bubble:hide`

```json
{
  "targetType": "user",
  "targetId": "uuid",
  "bubbleType": "typing"
}
```

### `notification:created`

```json
{
  "id": "uuid",
  "type": "deskMessageReceived",
  "title": "Novo recado na sua mesa",
  "body": "Luiz deixou um recado para você."
}
```

### `webrtc:offer`

```json
{
  "fromUserId": "uuid",
  "sdp": "v=0\r\no=...\r\n..."
}
```

### `webrtc:answer`

```json
{
  "fromUserId": "uuid",
  "sdp": "v=0\r\no=...\r\n..."
}
```

### `webrtc:ice-candidate`

```json
{
  "fromUserId": "uuid",
  "candidate": {
    "candidate": "candidate:...",
    "sdpMid": "0",
    "sdpMLineIndex": 0
  }
}
```

### `webrtc:hangup`

```json
{
  "fromUserId": "uuid"
}
```

## Regras realtime

- Movimento deve ter rate limit por conexão.
- Backend nunca confia totalmente na posição enviada pelo client.
- `typing.start` expira automaticamente se não houver renovação ou `typing.stop`.
- Convites expiram em `30s` por padrão.
- Balões obedecem prioridade de `03-component-animation-spec.md`.
- Eventos de sala são enviados apenas a participantes e usuários autorizados.
- Eventos privados usam canal `user:{userId}`.
- Eventos `webrtc:*` são relay puro: backend encaminha ao `targetUserId` sem interpretar SDP ou ICE.
- Backend só encaminha `webrtc:*` se ambos os usuários estiverem no mesmo `floorId` e workspace.
- `webrtc:hangup` deve ser emitido automaticamente ao desconectar WebSocket (cleanup no disconnect handler).
- Detecção de proximidade e criação de peer connections é responsabilidade exclusiva do client.
