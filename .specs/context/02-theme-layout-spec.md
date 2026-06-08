# Theme & Layout Spec — Gather-like Light/Dark

## Direção visual

Tema inspirado no Gather: escritório 2D em pixel art, legível, colorido sem excesso, com UI de produto SaaS sobreposta ao mapa. A interface deve parecer um app de trabalho vivo, não landing page.

Referências locais:

- `images/ChatGPT Image 4 de jun. de 2026, 12_42_53 (1).png` — poses de avatar.
- `images/ChatGPT Image 4 de jun. de 2026, 12_51_54.png` — ícones, gestos, balões e toolbar.
- `images/ChatGPT Image 4 de jun. de 2026, 12_56_02.png` — móveis e objetos.
- `images/ChatGPT Image 4 de jun. de 2026, 12_56_10.png` — tiles, paredes, divisórias e sala.
- `images/ChatGPT Image 4 de jun. de 2026, 12_56_29.png` — customização modular.
- `images/ChatGPT Image 4 de jun. de 2026, 12_56_36.png` — roupas e paletas.

## Princípios de layout

- Primeira tela após login deve ser o escritório utilizável, não uma página promocional.
- Mapa ocupa o centro e deve ser o principal sinal visual.
- UI flutuante deve ficar sobre o canvas sem cobrir avatar, card de proximidade ou balões.
- Controles frequentes ficam em toolbar inferior compacta.
- Chat e lista de usuários são painéis laterais recolhíveis.
- Modais só para tarefas focadas: recado, convite, confirmação, customização e admin.
- Não usar cards dentro de cards.
- Componentes devem ter altura estável para evitar saltos durante animações.
- Tipografia de painel deve ser compacta; hero-scale typography não deve aparecer dentro do app.

## Tokens globais

### Grid e pixel art

- Tile padrão: `32x32`.
- Avatar base: `32x48` ou `48x64`, definido por asset pack.
- Escala do canvas: múltiplos inteiros sempre que possível.
- Hitbox do avatar: menor que sprite visual; padrão `20x28` centralizado.
- Raio de proximidade usuário/mesa: `2.5 tiles`.
- Raio de grito: `8 tiles`.
- Duração mínima de tooltip: `150ms` para abrir, `100ms` para fechar.

### Raio e borda

- Painéis e cards: `8px`.
- Botões pequenos: `6px`.
- Ícones pixelados dentro de botões: sem suavização quando renderizados como sprite.
- Borda padrão: `1px`.
- Borda de destaque: `2px`.

### Elevação

- Overlay leve: sombra `0 4 12 rgba(0,0,0,0.16)`.
- Popover/card contextual: sombra `0 8 24 rgba(0,0,0,0.22)`.
- Modal: sombra `0 16 48 rgba(0,0,0,0.32)`.

## Paleta Light Mode

### Base

- `bg.canvas`: `#F3F6FA`
- `bg.app`: `#EEF3F8`
- `bg.panel`: `#FFFFFF`
- `bg.panelMuted`: `#F7F9FC`
- `bg.toolbar`: `#D8E1EC`
- `bg.tooltip`: `#111827`

### Texto

- `text.primary`: `#172033`
- `text.secondary`: `#4B5870`
- `text.muted`: `#7A869A`
- `text.inverse`: `#FFFFFF`

### Bordas

- `border.default`: `#C7D2E1`
- `border.strong`: `#8EA0B8`
- `border.focus`: `#4267D6`

### Cores Gather-like / produto

- `brand.primary`: `#4267D6`
- `brand.primaryHover`: `#3657BA`
- `brand.secondary`: `#6D5BD7`
- `brand.cyan`: `#39A9DB`
- `brand.green`: `#35A85A`
- `brand.yellow`: `#F2C94C`
- `brand.orange`: `#F2994A`
- `brand.red`: `#E5484D`
- `brand.purple`: `#8B5CF6`

### Estados de presença

- `presence.available`: `#35A85A`
- `presence.away`: `#F2C94C`
- `presence.busy`: `#E5484D`
- `presence.meeting`: `#4267D6`
- `presence.focus`: `#8B5CF6`
- `presence.offline`: `#9AA3B2`

## Paleta Dark Mode

### Base

- `bg.canvas`: `#111827`
- `bg.app`: `#0D1320`
- `bg.panel`: `#1B2433`
- `bg.panelMuted`: `#253143`
- `bg.toolbar`: `#2B3A50`
- `bg.tooltip`: `#F8FAFC`

### Texto

- `text.primary`: `#F8FAFC`
- `text.secondary`: `#CBD5E1`
- `text.muted`: `#94A3B8`
- `text.inverse`: `#111827`

### Bordas

- `border.default`: `#344256`
- `border.strong`: `#53647D`
- `border.focus`: `#7DA2FF`

### Cores de ação

- `brand.primary`: `#7DA2FF`
- `brand.primaryHover`: `#A8BEFF`
- `brand.secondary`: `#A78BFA`
- `brand.cyan`: `#67D8FF`
- `brand.green`: `#55C978`
- `brand.yellow`: `#F6D365`
- `brand.orange`: `#FFB066`
- `brand.red`: `#FF6B70`
- `brand.purple`: `#B69CFF`

### Estados de presença

- `presence.available`: `#55C978`
- `presence.away`: `#F6D365`
- `presence.busy`: `#FF6B70`
- `presence.meeting`: `#7DA2FF`
- `presence.focus`: `#B69CFF`
- `presence.offline`: `#64748B`

## Mapa em light/dark

### Light

- Pisos claros: madeira clara, porcelanato claro, carpete azul/verde/cinza.
- Paredes: off-white com contorno cinza-azulado.
- Móveis: madeira média, preto, azul, verde e cinza.
- Vidros: azul-claro com brilho.
- Zonas interativas: tracejado colorido discreto.

### Dark

- O mapa não deve virar monocromático.
- Escurecer piso e paredes mantendo contraste dos objetos.
- Usar overlay noturno `rgba(8, 14, 24, 0.25)` apenas se preservar leitura.
- Avatares, balões e zonas interativas continuam com cores vivas.
- Painéis dark não devem cobrir o mapa com blocos pretos grandes.

## Layout principal do app

### Desktop

- Canvas: ocupa `100vw x 100vh`.
- Top bar: altura `48px`, transparente/semissólida, com organização, workspace, status e notificações.
- Toolbar inferior: centralizada, altura `48px`, largura conforme ações, gap `6px`.
- Chat lateral: direita, largura `360px`, recolhível para `48px`.
- Lista de online: esquerda ou dentro do chat, largura `280px` quando aberta.
- Mini mapa futuro: canto inferior esquerdo, `160x120`, opcional fora do MVP.

### Mobile/tablet futuro

- Canvas continua tela inteira.
- Toolbar vira bottom sheet horizontal.
- Chat abre como drawer.
- Controles de movimento podem virar joystick virtual apenas em fase futura.

## Tipografia

- UI: fonte sans legível do sistema ou `Inter`.
- Labels pixel art opcionais apenas dentro de sprites/asset sheets.
- Tamanho base: `14px`.
- Botões compactos: `13px`.
- Títulos de painel: `16px`, peso `600`.
- Texto de chat: `14px`.
- Nome acima do avatar: `11px` a `12px`, com fundo/outline para contraste.

## Acessibilidade

- Contraste mínimo WCAG AA para texto em painéis.
- Controles icon-only devem ter tooltip e label acessível.
- Foco de teclado visível com `border.focus`.
- Movimento reduzido: substituir bounce, pulse e shake por fade discreto quando `prefers-reduced-motion`.
- Cores de presença devem ter texto/ícone complementar, não depender só da cor.
