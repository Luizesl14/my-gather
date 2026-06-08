# 38 — Room UI & Meeting Spec

## Objetivo

Implementar salas e entrada/saída.

## Componentes

- `RoomComponent`
- `RoomParticipantsPanel`
- `RoomEntryHint`

## Estados

- Vazia.
- Ocupada.
- Em reunião.
- Bloqueada.
- Foco.

## Ações

- Entrar.
- Sair.
- Ver participantes.
- Convidar.
- Começar reunião externa.

## Critérios de aceite

- Entrar em sala muda canal.
- Status muda para reunião quando aplicável.
