# 39 — Chat Panel Spec

## Objetivo

Implementar chat global, sala, privado e mesa.

## Componentes

- `ChatPanel`
- `ConversationList`
- `MessageList`
- `MessageInput`
- `TypingIndicatorRow`

## Estados

- Recolhido.
- Expandido.
- Loading histórico.
- Empty.
- Erro.

## Critérios de aceite

- Mensagem envia/recebe.
- Histórico carrega.
- Typing aparece e expira.
- Draft por canal é preservado.
