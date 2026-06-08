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

## Critérios de aceite

- Fora do raio, ação local falha.
- Chamada expira em `30s`.
