# 30 — WebRTC Proximity — Áudio e Vídeo por Proximidade

## Objetivo

Implementar áudio e vídeo automáticos baseados em proximidade de avatares, replicando o modelo do Gather: quando dois avatares entram no raio de interação, câmera e microfone conectam automaticamente via WebRTC; quando saem do raio, a conexão encerra.

## Conceito de Proximidade

### Raio de interação

- Definido em **tiles** (unidade do mapa), não em pixels.
- Valor padrão: `4 tiles` de raio.
- Usuário pode ajustar no perfil: `2`, `4`, `6` ou `8` tiles.
- Raio é **não-transitivo**: se A vê B e C, B e C podem não se ver entre si.

### Cálculo no client

```
distância = sqrt((ax - bx)² + (ay - by)²)
se distância <= raioLocal → emitir proximity:enter
se distância > raioLocal  → emitir proximity:leave
```

- Cálculo roda no client a cada `avatar:moved` recebido.
- Backend não calcula proximidade — apenas propaga posições.
- Estado de proximidade é **local** por client; não é persistido.

---

## Fluxo WebRTC (Signaling via WebSocket)

### Participantes: Iniciador (quem detecta) e Receptor

```
CLIENT A (detectou proximidade)          BACKEND (relay)         CLIENT B
│                                            │                       │
│── proximity:enter ────────────────────────►│                       │
│                                            │                       │
│── webrtc:offer ───────────────────────────►│──── webrtc:offer ────►│
│                                            │                       │
│◄── webrtc:answer ─────────────────────────│◄─── webrtc:answer ────│
│                                            │                       │
│── webrtc:ice-candidate ───────────────────►│── webrtc:ice-candidate►│
│◄── webrtc:ice-candidate ──────────────────│◄─ webrtc:ice-candidate─│
│                                            │                       │
│◄══ PEER CONNECTION ESTABELECIDA ══════════════════════════════════►│
│                                            │                       │
│── proximity:leave ────────────────────────►│                       │
│── webrtc:hangup ──────────────────────────►│──── webrtc:hangup ───►│
│                                            │                       │
│◄══ PEER CONNECTION ENCERRADA ═════════════════════════════════════►│
```

### Regras de signaling

- Backend é **relay puro**: não interpreta SDP nem ICE, apenas encaminha ao `targetUserId`.
- Cada par de usuários tem exatamente **uma** `RTCPeerConnection`.
- O usuário com `userId` menor (string sort) é sempre o **iniciador** (evita double-offer).
- Se já existir peer connection entre A e B, ignorar novo `proximity:enter`.

---

## Eventos WebSocket

### Client → Server

#### `webrtc:offer`
```json
{
  "targetUserId": "uuid",
  "sdp": "v=0\r\no=...\r\n..."
}
```

#### `webrtc:answer`
```json
{
  "targetUserId": "uuid",
  "sdp": "v=0\r\no=...\r\n..."
}
```

#### `webrtc:ice-candidate`
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

#### `webrtc:hangup`
```json
{
  "targetUserId": "uuid"
}
```

### Server → Client

#### `webrtc:offer`
```json
{
  "fromUserId": "uuid",
  "sdp": "v=0\r\no=...\r\n..."
}
```

#### `webrtc:answer`
```json
{
  "fromUserId": "uuid",
  "sdp": "v=0\r\no=...\r\n..."
}
```

#### `webrtc:ice-candidate`
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

#### `webrtc:hangup`
```json
{
  "fromUserId": "uuid"
}
```

---

## Áudio Espacial

### Modelo de atenuação

```
volumeNormalizado = max(0, 1 - distância / raioMaximo)
gainNode.gain.value = volumeNormalizado
```

- `raioMaximo` = raio de interação configurado pelo usuário.
- Volume é `1.0` quando avatares estão sobrepostos.
- Volume é `0.0` na borda do raio.
- Atualiza a cada evento `avatar:moved`.
- Implementado via **Web Audio API**: `AudioContext → GainNode` por peer.

### Múltiplos peers

- Cada `RTCPeerConnection` tem seu próprio `GainNode`.
- Mix final é automático pelo `AudioContext`.

---

## Entidades de domínio (Flutter Web)

### `ProximitySession`
- `peerId: String` (userId do peer)
- `peerConnection: RTCPeerConnection`
- `localStream: MediaStream`
- `remoteStream: MediaStream`
- `gainNode: AudioNode`
- `distance: double`
- `state: ProximitySessionState`

### `ProximitySessionState`
```
detecting → connecting → connected → disconnecting → closed
```

### `ProximitySessions` (mapa de sessões ativas)
- Chave: `userId` do peer
- Valor: `ProximitySession`

---

## Componentes de UI

### `ProximityVideoOverlay`
- Exibe miniaturas de vídeo dos peers próximos.
- Posição: canto superior direito do canvas.
- Layout: grade de até 4 miniaturas (2×2), expansível.
- Avatar sem câmera mostra placeholder com inicial do nome.

### `MediaControlBar` (dentro da toolbar)
- Microfone: toggle mudo/ativo.
- Câmera: toggle ligada/desligada.
- Ícone de qualidade de conexão por peer (opcional MVP).

### `ProximityIndicator` (acima do avatar no mapa)
- Ícone de microfone ativo quando peer está conectado.
- Ícone de câmera desligada quando peer está com câmera off.

---

## Configurações de mídia

### Permissões
- Solicitar permissão de câmera e microfone **na primeira entrada no workspace**.
- Se usuário negar, funciona apenas com chat/gestos (sem AV).
- Estado de permissão persiste via `localStorage`.

### Restrições de mídia
```json
{
  "audio": {
    "echoCancellation": true,
    "noiseSuppression": true,
    "sampleRate": 44100
  },
  "video": {
    "width": 320,
    "height": 240,
    "frameRate": 15
  }
}
```

---

## Modo Spotlight (sala de reunião)

Quando o usuário entra em uma `MeetingRoom`:
- **Desativa** o sistema de proximidade (para de criar novas peer connections por raio).
- **Cria peer connections** com todos os participantes da sala, independente de distância.
- Participante com papel `presenter` tem áudio/vídeo transmitido a todos.
- Saindo da sala → retorna ao modo proximidade.

---

## Infraestrutura

### STUN/TURN
- STUN público (Google): `stun:stun.l.google.com:19302`
- TURN próprio para produção (Coturn ou serviço gerenciado).
- Configuração via variável de ambiente `TURN_URL`, `TURN_USERNAME`, `TURN_CREDENTIAL`.

### Dependência Flutter
- Pacote: `flutter_webrtc: ^0.x`
- Suporta Web, Android, iOS e Desktop.

---

## Regras

- Peer connection só é criada quando ambos os usuários estão no mesmo `floorId`.
- Usuário com câmera desligada ainda recebe áudio do peer.
- Usuário mutado ainda recebe vídeo/áudio do peer.
- Ao fechar aba/desconectar WebSocket, `webrtc:hangup` é emitido automaticamente.
- Máximo de `8` peer connections simultâneas por client (performance).
- Se peer connections > 8, priorizar os peers com menor distância.

---

## Critérios de aceite

- Dois avatares no mesmo floor dentro do raio → vídeo e áudio conectam automaticamente.
- Sair do raio → vídeo e áudio desconectam sem ação manual.
- Volume diminui proporcionalmente à distância dentro do raio.
- Usuário pode mutar microfone sem encerrar peer connection.
- Usuário pode desligar câmera sem encerrar peer connection.
- Ao desligar câmera, peer vê placeholder (inicial do nome).
- Modo spotlight em sala de reunião ignora raio e conecta todos os participantes.
- Máximo de 8 peers simultâneos; conexões além do limite não travam o app.
- Permissão negada não quebra o app; funciona sem AV.
- WebSocket cai → peer connections encerram graciosamente.

---

## Não fazer ainda

- Gravação de reunião.
- Transcrição automática.
- Blur de fundo ou efeitos de câmera.
- TURN próprio em desenvolvimento (usar STUN público).
