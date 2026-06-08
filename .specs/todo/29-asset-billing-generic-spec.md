# 29 — Asset, Billing & Generic Domains Spec

## Objetivo

Separar domínios genéricos e suporte não centrais.

## Asset

Entidades:

- `AssetPack`
- `SpriteAsset`
- `TilesetAsset`
- `AnimationAsset`
- `ObjectAsset`

Regras:

- Asset tem tipo, path, versão e collision mask quando aplicável.
- Workspace referencia asset pack por ID.

## Billing

Planos:

- Free
- Starter
- Pro
- Enterprise

## Genéricos

- File Storage.
- Email Delivery.
- Audit Log.
- Observability.

## Critérios de aceite

- Portas ficam isoladas.
- Implementação externa não vaza para domínio.
