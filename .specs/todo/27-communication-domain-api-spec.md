# 27 — Communication Domain & API Spec

## Objetivo

Implementar conversas, mensagens, typing e recados.

## Entidades

- `Conversation`
- `Message`
- `Channel`
- `TypingIndicator`
- `DeskNote`

## Canais

- global
- sala
- privado
- mesa
- proximidade futuro

## Endpoints/eventos

- `GET /conversations/:conversationId/messages`
- `POST /conversations/:conversationId/messages`
- `GET /rooms/:roomId/messages`
- `chat:message.send`
- `chat:typing.start`
- `chat:typing.stop`

## Critérios de aceite

- Mensagens persistem.
- Typing não persiste.
- Recado de mesa persiste.
