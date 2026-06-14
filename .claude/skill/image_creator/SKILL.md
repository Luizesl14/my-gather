---
name: image_creator
description: Use esta skill para criar, editar ou orientar geracao de imagens bitmap com alto aproveitamento de prompts, referencias visuais e ferramentas de IA generativa. Acione quando o pedido envolver arte, concept art, mockups, assets visuais, capas, thumbnails, ilustracoes, texturas ou imagens para produto.
---

# Image Creator

## Objetivo

Gerar imagens com resultado util na menor quantidade possivel de tentativas. Antes de gastar credito em ferramenta externa, transforme o pedido em um briefing testavel.

## Fluxo

1. Defina o uso final: app, jogo, marketing, UI, referencia de arte, textura, personagem, cenario ou objeto.
2. Identifique restricoes: formato, proporcao, fundo, estilo, resolucao, paleta, publico, plataforma e elementos proibidos.
3. Se faltar informacao critica, faca no maximo 2 perguntas. Se nao for critica, assuma e documente a suposicao.
4. Crie um prompt principal e, quando util, um prompt negativo.
5. Para economizar creditos, gere primeiro baixa resolucao ou rascunho quando a ferramenta permitir.
6. Avalie o resultado contra o briefing antes de pedir nova variacao.
7. Refine mudando poucos parametros por vez.

## Prompt Base

Use esta estrutura:

```text
Subject: [objeto/personagem/cenario principal]
Purpose: [onde sera usado]
Composition: [enquadramento, camera, pose, layout]
Style: [linguagem visual, referencia tecnica, acabamento]
Lighting/Color: [luz, contraste, paleta]
Constraints: [proporcao, fundo, transparencia, sem texto, sem watermark]
Quality: sharp, clean silhouette, production-ready, coherent details
Negative: blurry, distorted anatomy, extra limbs, text, logo, watermark, cropped subject
```

## Regras de Economia

- Nao gere imagens sem briefing suficiente para julgar sucesso.
- Prefira 1 imagem bem especificada a muitas variacoes vagas.
- Use referencias existentes do projeto quando houver.
- Reaproveite seeds, estilo, paleta e descricoes aprovadas.
- Peca upscale apenas depois de aprovar composicao e estilo.
- Evite pedir texto renderizado dentro da imagem; adicione texto depois no app/design.

## Criterios de Aceite

- A imagem atende ao uso final.
- O assunto principal esta legivel em tamanho real.
- A composicao nao corta partes importantes.
- Nao ha watermark, texto acidental ou artefatos obvios.
- O arquivo final tem formato e proporcao adequados ao destino.
