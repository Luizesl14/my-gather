# Modular Avatar Assets

Esta pasta e a biblioteca fonte para o avatar customizavel no estilo Gather.
Ela nao substitui imediatamente os personagens prontos em `web/assets/sprites/characters`.
Tudo que for gerado aqui deve ser validado antes de ser copiado para `web/assets/`.

## Objetivo

O app hoje usa personagens completos por `characterId`. O novo modelo separa:

- `body`: corpo base, rosto e pele.
- `hair`: cabelo como overlay.
- `outfit`: roupas e sapatos como overlays.
- `accessory`: oculos, cracha, headset, chapeu e outros overlays.
- `state`: presenca, animacao, status e reacoes.

Fisica, velocidade, colisao e ponto de ancoragem continuam iguais para todos.

## Relacao Entre Pastas

```txt
assets/sprites/customization/
  body/          # fonte de corpos base gerados/processados
  outfits/       # fonte de roupas e sapatos
  accessories/   # fonte de acessorios
  hair/          # cabelo modular ja existente
  prompts/       # prompts aprovados para Magnific

web/assets/sprites/customization/
  modular-avatar-catalog.json  # criado somente depois da validacao
  hair/                        # overlays atuais de cabelo
```

## Fluxo De Validacao

1. Gerar a imagem no Magnific.
2. Remover fundo e garantir alpha real.
3. Processar, cortar e redimensionar para `32x48`.
4. Salvar primeiro nesta pasta `assets/sprites/customization/...`.
5. Validar visualmente em tamanho real e ampliado.
6. So depois promover para `web/assets/sprites/customization/...`.
7. So depois atualizar catalogos consumidos pelo Flutter.

## Contrato De Frame

Cada layer visual deve respeitar o mesmo grid dos personagens atuais:

- sprite final: `32x48`;
- ancora logica: centro inferior do sprite;
- hitbox fisica: fixa, baseada nos pes, nao no desenho;
- direcoes: `front`, `back`, `left`, `right`;
- animacoes opcionais: `idle` e `walk`;
- fundo: transparente.

## Ordem De Render

```txt
body
outfitBottom
outfitTop
shoes
hair
accessories
reaction/status/name
```

## Regra Principal

Uma opcao cosmetica nunca pode mudar colisao, velocidade, alcance de interacao
ou vantagem mecanica. Ela muda apenas a aparencia.
