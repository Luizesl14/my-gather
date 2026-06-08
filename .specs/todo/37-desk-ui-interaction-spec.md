# 37 — Desk UI & Interaction Spec

## Objetivo

Implementar mesa, proximidade e ações contextuais.

## Componentes

- `DeskComponent`
- `ContextActionCard`
- `DeskNoteModal`

## Estados da mesa

- Sem dono.
- Dono disponível.
- Dono ausente.
- Dono ocupado.
- Dono na mesa.
- Recado não lido.
- Chamada pendente.

## Ações

- Chamar.
- Acenar.
- Bater.
- Deixar recado.
- Café.

## Critérios de aceite

- Card aparece no raio correto.
- Recado salva.
- Chamada gera notificação.
