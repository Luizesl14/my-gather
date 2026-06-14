# 26 — Interaction Domain Spec

## Objetivo

Implementar ações sociais, gestos, reações e interações contextuais.

## Entidades

- `Interaction`
- `Gesture`
- `Reaction`
- `InteractionBubble`
- `InteractionRequest`

## Tipos MVP

- `Wave`
- `CallUser`
- `KnockDesk`
- `LeaveMessage`
- `Shout`
- `SendCoffeeInvite`
- `AskForHelp`
- `SendReaction`

## Regras

- Interações podem exigir proximidade.
- Convites expiram.
- Algumas interações geram notificação.
- Algumas interações geram balão.
- Proximidade avatar→avatar também aciona WebRTC (ver `30-webrtc-proximity-spec.md`).
- O raio de interação social (gestos, acenar, café) usa o mesmo raio do WebRTC.

## Critérios de aceite

- Fora do raio, ação local falha.
- Chamada expira em `30s`.
- `proximity:user.detected` deve incluir flag `webrtcAvailable: true` quando câmera/mic estiverem disponíveis.
