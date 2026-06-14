---
name: character_designer_magnific
description: Skill completo para criar personagens pixel art customizados com IA. Orquestra geração de imagem via Magnific, processamento em sprites com fundo transparente, animação e registro automático. Use quando precisar criar novo personagem para o jogo.
tools: Read, Write, Edit, Bash, WebFetch
---

# Character Designer Magnific - Skill Completo

## 🎯 Objetivo

Criar um personagem pixel art completo do zero:
1. Coletar specs do personagem (nome, descrição, estilo)
2. Gerar imagem base com Magnific (IA)
3. Processar em sprite sheet com 16 frames (4 idles + 12 walk)
4. Fundo 100% transparente
5. Salvar em `images/[nome]/`
6. Gerar preview e referências
7. Pronto para integração no jogo

## 📋 Fluxo de Trabalho

### Fase 1: Coleta de Specs

Quando o usuário chamar, pergunte:

```
🎨 DESIGNER MAGNIFIC - Novo Personagem

1️⃣ INFORMAÇÕES BÁSICAS
   - Nome do personagem: [?]
   - Descrição: [ex: garota loura, pele clara, camisa marrom]
   - Gênero: [M/F/Outro]

2️⃣ ESTILO VISUAL
   Escolha um ou mais:
   ☐ Anime/Manga
   ☐ Cartoon/Cute
   ☐ Retro/8-bit
   ☐ Chibi (formato curto)
   ☐ Realista simplificado
   ☐ Outro: [?]

3️⃣ CARACTERÍSTICAS FÍSICAS
   - Cabelo: [cor, comprimento, estilo]
   - Pele: [tom/cor]
   - Roupas: [descrição]
   - Acessórios: [opcional]
   - Características especiais: [opcional]

4️⃣ TAMANHO E PROPORÇÃO
   - Tamanho de sprite: ☐ 16×24  ☐ 32×48  ☐ 48×64  ☐ 64×96
   - Proporção de corpo: ☐ Realista  ☐ Chibi (cabelo grande)  ☐ Outro

5️⃣ ANIMAÇÕES NECESSÁRIAS
   ☑️ Default: 4 idles (front, back, left, right)
   ☑️ Default: 12 walk frames (3×4 direções)
   ☐ Extras: [attack, dance, special, etc - opcional]

6️⃣ CONTEXTO
   - Projeto: [love+robot]
   - Papel: [jogador, NPC, inimigo, etc]
   - Notas adicionais: [?]
```

### Fase 2: Geração de Imagem

**Use MCP Magnific com este prompt base:**

```
Create a [ESTILO] pixel art character [GÊNERO], [DESCRIÇÃO].
Style: crisp [ESTILO SELECIONADO], limited palette, clean silhouette, 
  readable at small size, chibi-proportioned if needed.
Pose: standing front view, neutral expression.
Technical: transparent background PNG, no antialiasing blur, 
  no shadow outside sprite bounds, no text, no watermark.
Quality: production-ready pixel art, consistent line weight.
Color: [PALETA SE ESPECIFICADA].
Avoid: photorealism, excessive detail, blurry edges, background elements.
```

**Parâmetros recomendados:**
- Model: Recraft V4.1 ou Flux.1 (melhor para TTI)
- Aspect Ratio: 3:4 (personagem em pé)
- Resolution: 1k (1024px)
- Count: 1

### Fase 3: Processamento em Sprites

**Script usado:** `scripts/create_claude_sprites.py`

Executa:
```bash
python3 scripts/create_claude_sprites.py \
  --input /tmp/[nome]-base.png \
  --id [nome] \
  --save-game
```

Gera automaticamente:
- ✅ 4 idles (front, back, left, right)
- ✅ 12 walk frames (walk-[dir]-01/02/03 para 4 direções)
- ✅ 16 PNGs individuais (32×48)
- ✅ sprite-sheet.png (referência visual)
- ✅ preview.png (128×192)

Localização final:
```
images/[nome]/
  ├── [nome]-sprite-sheet.png
  ├── [nome]-preview.png
  └── (individual frames opcionais)

web/assets/sprites/characters/[nome]/
  ├── idle-front.png
  ├── idle-back.png
  ├── walk-down-01.png
  ├── ... (16 arquivos)
  └── preview.png
```

### Fase 4: Registro Automático (Opcional)

Se o usuário aprovar, registre no catálogo:

**Atualize:** `web/assets/sprites/characters/characters.json`

Adicione entrada:
```json
{
  "id": "[nome]",
  "displayName": "[NOME_DISPLAY]",
  "description": "[descrição breve]",
  "default": false,
  "frames": {
    "idleFront": "[nome]/idle-front.png",
    "idleBack": "[nome]/idle-back.png",
    "idleLeft": "[nome]/idle-left.png",
    "idleRight": "[nome]/idle-right.png",
    "walkDown": ["[nome]/walk-down-01.png", "...02...", "...03..."],
    "walkLeft": [...],
    "walkRight": [...],
    "walkUp": [...]
  },
  "hitbox": { "x": 6, "y": 22, "w": 20, "h": 24 }
}
```

**Atualize:** `web/pubspec.yaml`

Adicione:
```yaml
    - assets/sprites/characters/[nome]/
```

## 🎨 Estilos Suportados

| Estilo | Descrição | Exemplo |
|--------|-----------|---------|
| Anime | Proporções realistas, olhos grandes | Carla, Morena |
| Cartoon | Formas simples, cores vibrantes | Matt |
| Chibi | Cabeça grande, corpo curto, cute | Robbit, Young |
| Retro | NES/SNES-like, pixels visíveis | 8-bit style |
| Manga | Traços finos, dinâmica | Action character |

## 🎯 Critérios de Aceite

Ao finalizar, valide:

- ✅ Fundo é 100% transparente (não branco)
- ✅ Sprite é legível no tamanho real (32×48 ou escolhido)
- ✅ Todos os 16 frames foram gerados
- ✅ Idles mostram 4 direções diferentes
- ✅ Walk frames mostram movimento/animação
- ✅ Sprite sheet de referência está correto
- ✅ Sem artefatos pixelados nas bordas
- ✅ Cores são consistentes entre frames
- ✅ Proporções mantidas entre poses

## 🚀 Comandos Úteis

**Listar personagens existentes:**
```bash
ls -1 images/
ls -1 web/assets/sprites/characters/
```

**Verificar sprite sheet gerado:**
```bash
file images/[nome]/[nome]-sprite-sheet.png
identify images/[nome]/[nome]-preview.png
```

**Testar carregamento no jogo:**
- Flutter rebuild com novo asset
- Character selection page deve listar novo personagem

## 💡 Dicas

1. **Prompt é chave**: quanto mais específico, melhor resultado Magnific
2. **Estilo consistente**: escolha um estilo e mantenha para todo o sprite
3. **Tamanho importa**: 32×48 é padrão, 48×64 dá mais detalhe
4. **Animação sutil**: walk frames diferem pouco de idle (posição de pernas/braços)
5. **Paleta limitada**: pixel art melhor com cores restritas (<16 cores por personagem)
6. **Transparência primeiro**: sempre com fundo transparente, não branco
7. **Teste zoom**: veja a imagem em 100%, 200% e 400% para validar

## 📊 Saída Esperada

Ao finalizar, entregue:

1. **Link/URL** da imagem gerada no Magnific
2. **Sprite sheet** visual em PNG (referência)
3. **Preview** 4× para visualizar
4. **Localização** dos arquivos:
   ```
   images/[nome]/[nome]-sprite-sheet.png ✅
   web/assets/sprites/characters/[nome]/idle-front.png ✅
   web/assets/sprites/characters/[nome]/... (14 more) ✅
   ```
5. **Status de registro**:
   - [ ] Adicionado a characters.json
   - [ ] Adicionado a pubspec.yaml
   - [ ] Pronto para testar no jogo
6. **Notas técnicas**:
   - Modelo Magnific usado
   - Tempo de geração
   - Ajustes feitos
   - Próximos passos (se houver)

## ⚠️ Limitações e Workarounds

| Problema | Causa | Solução |
|----------|-------|---------|
| Fundo não fica transparente | Magnific gera branco | Rodar `remove_checker_background()` |
| Sprite pixelado nas bordas | Anti-aliasing IA | Usar "crisp, no blur" no prompt |
| Animação não flui | Poses muito diferentes | Manter posição base, variar só pernas/braços |
| Arquivo muito grande | PNG não comprimido | Use `pngquant` ou converter para indexed |
| Caractere fica muito pequeno | Proporção de sprite | Aumentar tamanho ou usar 64×96 |

## 🔗 Referências

- **Magnific**: https://www.magnific.com
- **Projeto**: love+robot (Flutter + Flame)
- **Sprite size**: 32×48 px (padrão), 96×144 px (canvas de trabalho)
- **Exemplos**: `images/person/`, `images/trae/`
- **Scripts**: `scripts/create_claude_sprites.py`

---

**Resumo do skill em uma frase:**
> "De spec → imagem IA → sprite transparente → pronto para jogo, tudo automatizado"
