# Assets Organizados

Esta pasta centraliza uma organizacao derivada de `images/trae/` seguindo o padrao funcional do projeto.

## Objetivo

- manter uma biblioteca organizada de assets ja recortados ou separados por dominio;
- preservar `images/trae/` como fonte original e historico visual;
- nao alterar `web/assets/`, que continua sendo a pasta de runtime do app web.

## Relacao Entre Pastas

- `images/trae/`: fonte original, sheets, previews e material de pipeline.
- `assets/`: biblioteca organizada na raiz, preparada por dominio.
- `web/assets/`: assets finais consumidos pelo app Flutter Web.

## Estrutura

```txt
assets/
  sprites/
    characters/
      normal/
      combat/
    customization/
      hair/
    bubbles/
      source/
    gestures/
      source/
  environment/
    themes/
      office/
      industrial/
  maps/
    models/
```

## Convencoes

- personagens normais ficam em `assets/sprites/characters/normal/`;
- personagens de combate ficam em `assets/sprites/characters/combat/`;
- cabelo modular fica em `assets/sprites/customization/hair/`;
- sheets de acoes ainda nao fatiadas ficam em `assets/sprites/bubbles/source/` e `assets/sprites/gestures/source/`;
- componentes e construcao ficam em `assets/environment/themes/<tema>/`;
- mapas-modelo ficam em `assets/maps/models/`.

## Regras

- nao mover nem remover nada de `images/trae/` sem necessidade explicita;
- nao assumir que `assets/` ja esta plugada no runtime;
- qualquer promocao de asset para `web/assets/` deve respeitar `pubspec.yaml`, `asset-pack.json` e os JSONs de catalogo do web;
- quando houver inconsistencias herdadas da fonte, manter o arquivo e documentar a excecao em vez de renomear no escuro.

## Observacoes

- alguns combats herdaram nomes de reacoes inconsistentes da fonte atual, como `gill-combat-02/reactions/`;
- esta pasta organiza o material atual, mas nao normaliza automaticamente nomes quebrados ou recortes ja existentes;
- a proxima etapa natural, se voce quiser, e mapear o que dessa raiz `assets/` deve ser promovido para `web/assets/`.
