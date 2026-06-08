# 28 — Meeting & Notification Spec

## Objetivo

Implementar salas de reunião, convites e notificações.

## Meeting

Entidades:

- `MeetingRoom`
- `MeetingSession`
- `MeetingParticipant`
- `CallInvite`

Estados:

- `Idle`
- `Waiting`
- `Active`
- `Locked`
- `Finished`

## Notification

Tipos:

- `UserCalled`
- `DeskMessageReceived`
- `MeetingInviteReceived`
- `MentionReceived`
- `HelpRequested`
- `CoffeeInviteReceived`

## Critérios de aceite

- Entrar em sala muda participante.
- Chamada gera notificação realtime.
- Notificação lida muda status.
