# 46 — UI Motion Spec

## Objetivo

Padronizar movimento de UI.

## Durações

- Hover: `120ms`.
- Pressed: `90ms`.
- Popover entrada: `140ms`.
- Popover saída: `100ms`.
- Drawer/chat: `180ms`.
- Toast entrada: `180ms`.
- Toast saída: `140ms`.

## Easing

- Padrão: `easeOutCubic`.
- Saída: `easeInCubic`.

## Reduced motion

- Trocar slide/bounce/shake por fade.
- Parar loops decorativos.

## Critérios de aceite

- Nenhum componente tem animação fora do padrão sem justificativa.
