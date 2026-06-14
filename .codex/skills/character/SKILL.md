---
name: character
description: Skill completo para criar personagens, components ou assets visuais pixel art. Orquestra especificação completa, geração com Magnific, processamento em sprites com fundo customizável, animação e registro automático. Faz perguntas complementares para clarificar estilo, background, proporções e contexto.
---

# Character Creator — Skill Consolidado

## 🎯 Objetivo

Criar personagens pixel art completos do zero com um fluxo interativo que clarifica todos os detalhes antes de gerar:

1. Coleta de specs do personagem (nome, descrição, estilo visual)
2. Perguntas complementares sobre estilo, background, proporções
3. Geração de imagem base com Magnific (IA)
4. Processamento em sprite sheet com 16 frames (4 idles + 12 walk)
5. Customização de background (transparente, branco, colorido)
6. Salvar em `images/[nome]/`
7. Gerar preview e referências
8. Registro automático no catálogo do jogo

## Contexto Do Projeto Love+Robot

Para personagens customizaveis no estilo escritorio virtual/Gather, use primeiro o briefing local em
`images/claude/README.md`, o contrato obrigatorio em `images/claude/LAYER_CONTRACT.md` e os prompts em
`images/claude/prompts/`.

Referencias obrigatorias do projeto:

- `images/trae/`: folhas modulares de estilo.
- `images/person/`: exemplos de personagens completos.
- `web/assets/sprites/characters/`: formato final usado pelo app.
- `web/assets/sprites/customization/avatar-creator.json`: catalogo de customizacao.

Quando a decisao depender de comportamento/estilo atual do Gather, pesquise na internet antes de gerar
ou especificar assets. Para economizar credito, gere por categoria aprovada: corpo base, cabelo-only,
roupas por frame, acessorios por frame e reacoes. Nao gere personagem final vestido antes das camadas
estarem corretas.

## 📋 Fase 1: Coleta Interativa de Specs

Quando o usuário chamar a skill, apresente este formulário:

```
🎨 CHARACTER CREATOR — Novo Personagem
═══════════════════════════════════════════════════════════════

1️⃣ INFORMAÇÕES BÁSICAS
   → Nome do personagem: [?]
   → Descrição: [ex: garota loura, pele clara, camisa marrom, óculos]
   → Tipo: ☐ Personagem jogável  ☐ NPC  ☐ Inimigo  ☐ Boss  ☐ Component visual
   → Gênero: [M/F/Outro]

2️⃣ TIPO DE CRIAÇÃO
   Escolha o que vai ser criado:
   ☐ Personagem completo (16 frames: 4 idles + 12 walk)
   ☐ Apenas poses estáticas (4 idles)
   ☐ Custom: [especifique número de frames/poses]
   ☐ Asset visual único (componente, prop, objeto)

3️⃣ ESTILO VISUAL
   Escolha o estilo predominante:
   ☐ Chibi (cabeça grande, corpo curto, cute, proporcional)
   ☐ Anime (proporções realistas, olhos grandes, traços definidos)
   ☐ Cartoon (formas simples, cores vibrantes, expressive)
   ☐ Disney-like (estilo clássico animado, harmônico)
   ☐ Realista simplificado (detalhe mas mantendo pixel art crisp)
   ☐ Retro/8-bit (NES/SNES-like, pixels visíveis)
   ☐ Manga (traços finos, dinâmico, expressivo)
   ☐ Outro: [descreva]

4️⃣ CARACTERÍSTICAS FÍSICAS
   - Cabelo: [cor, comprimento, estilo - ex: louro liso, curto]
   - Pele: [tom/cor - ex: clara, bronzeada, verde (fantasia)]
   - Roupas: [descrição - ex: camisa marrom, calça azul, botas]
   - Acessórios: [opcional - ex: óculos, chapéu, jóias]
   - Características especiais: [opcional - ex: cicatriz, asas, cauda (fantasia)]

5️⃣ BACKGROUND & CONTEXTO
   - Background: ☐ Transparente (PNG com alpha)  ☐ Branco sólido  ☐ Colorido [cor]
   - Contexto do jogo: [ex: ambiente futurista, medieval, moderno]
   - Papel na história: [ex: protagonista feminino, vilão, mentor]
   - Notas adicionais: [qualquer outra info relevante]

6️⃣ TAMANHO E PROPORÇÃO
   - Tamanho de sprite: ☐ 16×24  ☐ 32×48 (padrão)  ☐ 48×64  ☐ 64×96
   - Proporção de corpo: ☐ Realista (7-8 cabeças)  ☐ Chibi (4-5 cabeças)  ☐ Custom [descrição]

7️⃣ REFERÊNCIAS
   - Tem foto da pessoa? [sim/não - se sim, onde?]
   - Estilos/personagens de referência? [ex: "tipo a Carla do jogo" ou referência externa]
   - Paleta de cores preferida? [ex: tons quentes, pastéis, saturation alta]
```

## 📋 Fase 2: Perguntas Complementares Contextuais

Dependendo das respostas, faça perguntas adicionais:

### Se Chibi foi selecionado:
- Quanto de exagero? (cabeça levemente grande → muito grande)
- Proporção de pernas? (curtas e grossas → normais mas pequenas)

### Se há características especiais (asas, cauda, etc):
- Como integrar na animação? (move junto → move independente)
- Física da animação? (bate com o vento → fluida e etérea)

### Se múltiplas camadas de roupa:
- Quais animam juntas? (jaqueta sobre camisa ou independente)
- Panos soltos vs. ajustados?

### Se é NPC ou inimigo:
- Expressão emocional padrão? (neutro, agressivo, amistoso)
- Detalhes que comunicam o papel?

### Se há referência visual:
- A proporção deve ficar próxima da referência?
- Qual a tolerância de interpretação estilística?

## 🎨 Fase 3: Construção do Prompt de Geração

Baseado nas respostas, construa este prompt para Magnific:

```
PROMPT ESTRUTURADO PARA MAGNIFIC:

[ESTILO] pixel art character [GÊNERO], [DESCRIÇÃO FÍSICA COMPLETA].

BACKGROUND: [transparente com alpha / branco sólido]

TECHNICAL REQUIREMENTS:
- Crisp pixel art, no antialiasing blur
- Limited palette (16-32 colors max)
- Clean silhouette, readable at small size
- No shadow outside sprite bounds
- No text, no watermark
- Fundo [transparente PNG / branco]

POSE: [idle-front description]
- Standing neutral pose facing camera
- Relaxed arms at sides
- Feet together or natural stance
- Full body visible

PROPORTIONS: [chibi/realista/custom]
- Head ratio: [cabeça grande / normal]
- Body size: [altura/largura specification]

STYLE DETAILS:
- Estilo predominante: [chibi, anime, cartoon, etc]
- Iluminação: [flat, soft, directional]
- Nível de detalhe: [minimalista, médio, rico]
- Cores: [paleta se especificada]

AVOID: photorealism, excessive detail, blurry edges, background elements, artifacts
```

## 🖼️ Fase 4: Geração com Magnific

**Parâmetros MCP recomendados:**
- Model: Recraft V4.1 ou Flux.1 (melhor para pixel art TTI)
- Aspect Ratio: 2:3 ou 3:4 (personagem em pé)
- Resolution: 1k (1024px)
- Count: 2 (escolha melhor antes de continuar)

**Fluxo de aprovação:**
1. Gere 2 variações
2. Mostre ao usuário via preview
3. Aprovação antes de continuar
4. Só após aprovação: remova background, redimensione, gere outros frames

## 🔄 Fase 5: Geração de Frames (Se aplicável)

### Para sprites completos (16 frames):

**4 IDLE FRAMES (estático em 4 direções):**
- idle-front: frente, para câmera
- idle-back: costas, afastando da câmera
- idle-left: perfil esquerda
- idle-right: perfil direita (espelho de left ou gerado novo)

**12 WALK FRAMES (3 frames × 4 direções):**
- walk-down: caminhando em direção à câmera (3 frames de stride)
- walk-up: caminhando se afastando (3 frames)
- walk-left: caminhando para esquerda (3 frames, perfil)
- walk-right: caminhando para direita (3 frames, perfil espelhado)

**Estratégia de créditos:**
- Não gere todos os 16 de uma vez
- Aprove idle-front primeiro
- Gere idle-back depois
- Use `images_variations` com angles para idle-left e mirror para idle-right
- Só após idles aprovados: gere walk frames
- Limite `count: 2` em cada chamada

### Para poses estáticas (4 idles):
Gere os 4 idles aprovando cada um progressivamente.

### Para assets únicos:
Gere apenas 1 pose/ângulo conforme especificado.

## 🎯 Fase 6: Processamento de Background

**Opções de background:**

1. **Transparente (PNG com alpha)**
   - Use `images_remove_background` do Magnific
   - Remova fundo checkerboard completamente
   - Valide transparency antes de salvar

2. **Branco sólido**
   - Após remove_background, preencha com #FFFFFF
   - Use script: `scripts/add_background.py --bg white`

3. **Colorido**
   - Especifique cor: `--bg #RRGGBB`
   - Use script: `scripts/add_background.py --bg "#FF6B9D"`

**Script de processamento:**
```bash
python3 scripts/process_character_frame.py \
  --input "/tmp/[nome]-raw.png" \
  --output "web/assets/sprites/characters/[nome]/idle-front.png" \
  --background [transparent|white|#RRGGBB] \
  --size 32x48
```

## 💾 Fase 7: Salvar e Registrar

**Estrutura de diretórios:**
```
images/[nome]/
  ├── [nome]-sprite-sheet.png (visual reference)
  └── [nome]-preview.png (128x192)

web/assets/sprites/characters/[nome]/
  ├── idle-front.png
  ├── idle-back.png
  ├── idle-left.png
  ├── idle-right.png
  ├── walk-down-01.png
  ├── walk-down-02.png
  ├── walk-down-03.png
  ├── walk-left-01.png
  ├── walk-left-02.png
  ├── walk-left-03.png
  ├── walk-right-01.png
  ├── walk-right-02.png
  ├── walk-right-03.png
  ├── walk-up-01.png
  ├── walk-up-02.png
  ├── walk-up-03.png
  └── preview.png (128x192 thumb)
```

**Registro automático:**
1. Atualizar `web/assets/sprites/characters/characters.json`
2. Adicionar entry no pubspec.yaml assets
3. Recompile Flutter/Dart se necessário

## 📊 Entrega Final

Ao finalizar, confirme:

✅ Especificação completa documentada
✅ Estilo visual aprovado pelo usuário
✅ Todos os frames gerados e aprovados
✅ Background conforme pedido (transparente/branco/colorido)
✅ Fundo é 100% do tipo solicitado (não branco onde deveria ser transparente)
✅ Sprite legível no tamanho real
✅ Idles mostram 4 direções diferentes
✅ Walk frames mostram movimento fluido
✅ Cores consistentes entre frames
✅ Proporções mantidas entre poses
✅ Sem artefatos ou pixelação excessiva nas bordas
✅ Arquivos salvos em local correto
✅ Registrado no catálogo do jogo (se applicável)

**Entrega:**
1. Link/URL da imagem no Magnific
2. Sprite sheet visual em PNG
3. Preview 4× (4 idles lado a lado)
4. Localização dos arquivos finais
5. Notas técnicas (modelo usado, tempo, ajustes)
6. Status de integração (pronto para testar no jogo)

## 🎨 Exemplos de Casos de Uso

### Caso 1: Novo personagem jogável chibi
- Entrada: "Quero um novo personagem feminino chibi, estilo cute"
- Perguntas: tamanho exato, fundo, roupa, acessórios
- Saída: 16 frames de sprite completo, fundo transparente, registrado

### Caso 2: NPC estático
- Entrada: "Quero um zelador de orfanato, realista"
- Perguntas: estilo, fundo branco ou transparente, expressão
- Saída: 4 idles apenas, fundo branco, não registra como jogável

### Caso 3: Component visual
- Entrada: "Quero um item visual: uma vassoura"
- Perguntas: tamanho, estilo, será animado ou estático
- Saída: 1 ou 4 frames conforme need, fundo transparente

### Caso 4: Inimigo com características especiais
- Entrada: "Robô inimigo com asas, estilo retro 8-bit"
- Perguntas: como as asas animam, movimento padrão, tamanho
- Saída: 16 frames com animação de asas, fundo transparente

## 🚀 Fluxo Rápido (Se tudo já definido)

Se o usuário já tem tudo claro:
1. Coleta rápida de specs (1-2 perguntas max)
2. Construa prompt
3. Gere base
4. Aprove/refine
5. Processe frames
6. Entregue

## ⚠️ Pontos de Decisão Críticos

Sempre clarifique ANTES de gastar créditos:

1. **Background type** — não gere transparente se quer branco
2. **Número de frames** — não gere 16 se só precisa 4 idles
3. **Estilo** — chibi vs realista muda todo o prompt
4. **Proporções** — cabeça grande vs normal é diferente generation
5. **Características especiais** — asas, cauda, múltiplas camadas precisa ser comunicado

## 🔗 Referências & Recursos

- **Magnific**: https://www.magnific.com
- **Projeto**: love+robot (Flutter + Flame)
- **Sprites existentes**: `web/assets/sprites/characters/`
- **Exemplos de request**: `.trae/ex/`
- **Scripts**: `scripts/process_character_frame.py`, `scripts/register_character.py`
- **Personagens existentes**: character-01 a character-06

---

**Resumo em uma frase:**
> "De pergunta → spec completa → imagem IA → sprite com background customizado → registrado no jogo"
