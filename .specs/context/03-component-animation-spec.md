# Component & Animation Spec

Todos os componentes devem funcionar em light e dark mode usando tokens de `02-theme-layout-spec.md`.

## Regras gerais de animação

- Animações de UI: `120ms` a `220ms`, easing `easeOutCubic`.
- Animações sociais: `800ms` a `5000ms`, conforme interação.
- Sprites de avatar: `6fps` a `10fps` para idle/walk.
- Eventos efêmeros devem ter início, duração, prioridade e expiração.
- Com `prefers-reduced-motion`, trocar movimento por fade/opacity e reduzir loops.

## OfficeCanvas

Responsabilidade: renderizar mapa, objetos, avatares, balões e hints.

Estados:

- `loadingMap`: fundo do canvas e spinner compacto.
- `ready`: mapa renderizado.
- `reconnecting`: overlay discreto no topo.
- `error`: mensagem curta e botão tentar novamente.

Animações:

- Pan/zoom: suave, `120ms`, sem blur.
- Entrada no escritório: fade do mapa `180ms`, avatar local aparece com pop `140ms`.
- Reconnect: barra superior pulsa a cada `1200ms`.

## MapLayerRenderer

Responsabilidade: desenhar camadas na ordem:

1. Piso.
2. Tapetes/decorativos.
3. Paredes/janelas/portas.
4. Móveis inferiores.
5. Objetos interativos.
6. Avatares.
7. Móveis superiores/overlays.
8. Balões/reacões.
9. UI hints.

Animações:

- Tiles estáticos não animam.
- Portas podem animar abertura em `4 frames / 300ms`.
- Água/café/luzes futuras podem animar em loops lentos `600ms` a `1200ms`.

## AvatarSprite

Estados visuais:

- `idleFront`
- `idleBack`
- `idleLeft`
- `idleRight`
- `walkingUp`
- `walkingDown`
- `walkingLeft`
- `walkingRight`
- `performingGesture`
- `receivingInteraction`
- `typing`
- `speaking`

Animações:

- Idle: frame fixo conforme direção; opcional blink a cada `4s-7s`.
- Walk: alternar 2 frames por direção, `8fps`.
- Interpolação remota: suavizar posição entre eventos, duração máxima `120ms`.
- Teleporte/correção de posição: se delta for maior que `3 tiles`, snap com fade `80ms`.
- Receber chamada: avatar ou indicador de status pulsa `3 vezes / 900ms`.

Regras:

- Nome do usuário fica acima do avatar, nunca sobre balão.
- Indicador de presença fica no canto inferior direito do avatar.
- Hitbox não deve usar o sprite completo.

## PresenceIndicator

Estados:

- `available`: verde.
- `away`: amarelo.
- `busy`: vermelho.
- `meeting`: azul.
- `focus`: roxo.
- `offline`: cinza.

Animações:

- Mudança de status: crossfade `160ms`.
- Online recém-entrado: pulse leve `600ms`.
- Offline: fade para cinza `300ms`.

## BottomActionToolbar

Responsabilidade: ações rápidas do usuário.

Itens MVP:

- Chat.
- Voz/chamada.
- Chamar usuário.
- Acenar.
- Café.
- Reunião.
- Ajuda.
- Gritar.
- Notificações.
- Mais ações.

Estados:

- `default`
- `hover`
- `pressed`
- `disabled`
- `active`
- `hasBadge`

Animações:

- Hover: elevar `2px` ou aumentar background em `120ms`.
- Pressed: scale `0.96` por `90ms`.
- Badge novo: pop `140ms` e pulse `2 vezes`.
- Toolbar abre/fecha: slide + fade `180ms`.

## ContextActionCard

Responsabilidade: ações por proximidade em usuário, mesa, sala ou objeto.

Variantes:

- `nearUser`
- `nearDesk`
- `nearRoom`
- `nearObject`

Conteúdo mínimo:

- Título.
- Status/descrição curta.
- Ações primárias.
- Ações secundárias compactas.

Animações:

- Entrada: fade + translateY `8px -> 0`, `140ms`.
- Saída: fade `100ms`.
- Troca de alvo: crossfade `120ms`.
- Ação executada: botão mostra loading compacto até confirmação.

Regras:

- Não aparecer se usuário estiver fora do raio.
- Não cobrir avatar local.
- Se houver várias proximidades, priorizar mesa/sala sob foco explícito, depois usuário mais próximo.

## ChatPanel

Responsabilidade: conversas global, sala, privada, mesa e proximidade futura.

Estados:

- `collapsed`
- `expanded`
- `roomContext`
- `privateContext`
- `deskContext`
- `loadingHistory`
- `empty`

Animações:

- Expandir/recolher: width `48px <-> 360px`, `180ms`.
- Nova mensagem: item fade/slide `120ms`.
- Menção: borda lateral pulse `800ms`.
- Typing row: pontos alternam `.` `..` `...` a cada `350ms`.

Regras:

- Indicadores de digitação não persistem.
- Mensagens persistentes usam status `sent`, `received`, `read`.
- Ao entrar em sala, canal ativo muda automaticamente para sala, preservando drafts por canal.

## MessageBubble

Variantes:

- `own`
- `other`
- `system`
- `deskNote`
- `quickSpeech`

Animações:

- Entrada: fade + translateY `6px`, `120ms`.
- Status enviado: check aparece por fade `100ms`.
- Mensagem rápida acima do avatar: duração `3000ms`, fade out `180ms`.

## InteractionBubble

Tipos:

- `typing`
- `speech`
- `voice`
- `call`
- `invite`
- `knock`
- `bell`
- `question`
- `alert`
- `shout`
- `coffee`
- `help`
- `reaction`

Prioridade:

1. `call`, `alert`
2. `help`, `shout`
3. `invite`, `coffee`, `knock`
4. `reaction`, `speech`
5. `typing`

Animações por tipo:

- `typing`: três pontos em loop `350ms` por ponto, enquanto digita ou até timeout.
- `speech`: balão aparece por `3000ms`, fade out `180ms`.
- `call`: ícone pulsa `3 vezes`, expira em `30s`.
- `invite`: slide leve de entrada e duração até aceitar/expirar.
- `knock`: shake horizontal `3 ciclos / 450ms`.
- `bell`: swing `600ms`, som opcional.
- `question`: bounce leve `700ms`.
- `alert`: pulse vermelho `5s`.
- `shout`: megafone com linhas expandindo `3s`.
- `coffee`: pop + pequeno vapor em loop `2s`, expira conforme convite.
- `help`: pulse azul/verde `4s`.
- `reaction`: pop `140ms`, flutua `12px` e some em `1800ms`.

## GestureAnimation

Gestos:

- `wave`: mão sobe e alterna 2 frames, `2s`.
- `raiseHand`: mão levantada estática com pulse `2s` ou enquanto ativo em sala.
- `point`: braço aponta para direção do alvo, `1500ms`.
- `thumbsUp`: pop, `1200ms`.
- `thumbsDown`: pop, `1200ms`.
- `clap`: alternar mãos `3 ciclos / 900ms`.
- `comeHere`: mão chama em loop `2s`.
- `handshake`: só quando dois usuários aceitam, `1500ms`.
- `stop`: mão parada com destaque `2s`.
- `peace`: pop `1200ms`.

Regras:

- Gestos visuais são efêmeros.
- Se uma chamada chegar durante gesto, chamada substitui o gesto no bubble stack.
- Gestos que exigem alvo devem validar proximidade quando aplicável.

## DeskComponent

Estados:

- `unassigned`
- `assignedAvailable`
- `assignedAway`
- `assignedBusy`
- `ownerAtDesk`
- `hasUnreadNotes`
- `beingKnocked`
- `callPending`

Animações:

- Mesa com dono online: indicador discreto aceso.
- Recado não lido: badge pop e pulse lento a cada `2200ms`.
- Bater na mesa: shake `450ms` + bubble `knock`.
- Chamar dono: glow azul `30s` ou até resposta.
- Dono sentado: cadeira/posição destaca sem bloquear avatar.

## RoomComponent

Estados:

- `empty`
- `occupied`
- `meetingActive`
- `locked`
- `focus`

Animações:

- Entrada na zona: contorno tracejado fade in `120ms`.
- Entrar na sala: porta abre `300ms`; avatar atravessa zona; status muda após confirmação.
- Sala ocupada: indicador de participantes com pulse muito leve `1600ms`.
- Sala bloqueada: lock icon estático; hover exibe motivo.

## NotificationToast

Tipos:

- Chamada recebida.
- Recado recebido.
- Convite de reunião.
- Menção.
- Ajuda.
- Café.
- Sistema.

Animações:

- Entrada: slide da direita + fade `180ms`.
- Saída: fade/slide `140ms`.
- Chamada: mantém visível até ação ou `30s`.
- Notificação leve: auto-dismiss `5000ms`.

## AvatarCustomizer

Componentes:

- Preview.
- Seletor de pele.
- Cabelo.
- Rosto/olhos/óculos.
- Top.
- Bottom.
- Sapatos.
- Acessórios.
- Gestos disponíveis.

Animações:

- Troca de item: preview crossfade `120ms`.
- Rotação de direção: snap entre frente, lado, costas com botão.
- Salvar: botão loading e toast de confirmação.

Regras:

- Toda combinação deve gerar fallback válido.
- Camadas seguem ordem definida em `06-map-assets-avatar-spec.md`.

## AdminMapPanel

Responsabilidade: criar salas, mesas, zonas e publicar mapa JSON.

Estados:

- `view`
- `selecting`
- `editingDesk`
- `editingRoom`
- `editingZone`
- `publishing`
- `validationError`

Animações:

- Seleção de objeto: contorno tracejado animado.
- Publicar mapa: progress discreto.
- Erro de colisão: highlight vermelho `1500ms`.

Regras:

- Alterações admin devem validar colisão e limites antes de publicar.
- MVP permite edição por JSON versionado; editor visual pode ficar futuro.
