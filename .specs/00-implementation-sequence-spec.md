# Implementation Sequence Spec — Atividades Granulares em Ordem

Esta spec é a fila operacional do projeto. Cada atividade deve ser executada individualmente, na ordem, sem pular dependências.

Formato:

- `Objetivo`: o que será entregue.
- `Criar/alterar`: arquivos e diretórios esperados.
- `Critério de aceite`: como saber que a atividade terminou.
- `Não fazer ainda`: limites para evitar escopo aberto.

## Fase 0 — Preparação do repositório

### ATV-0001 — Criar estrutura raiz do monorepo

Objetivo: criar as pastas principais do projeto.

Criar/alterar:

- `backend/`
- `web/`
- `infra/`
- `docs/`
- `scripts/`
- `.gitignore`
- `README.md`

Critério de aceite:

- Pastas existem na raiz.
- `README.md` descreve o projeto em português.
- `.gitignore` cobre Node, Flutter, Docker, logs, env e arquivos temporários.

Não fazer ainda:

- Não instalar dependências.
- Não criar código de domínio.

### ATV-0002 — Criar documentação base em `docs/`

Objetivo: espelhar as specs principais em documentação de produto e arquitetura.

Criar/alterar:

- `docs/PRD.md`
- `docs/FSD.md`
- `docs/ADR.md`
- `docs/UBIQUITOUS_LANGUAGE.md`
- `docs/DOMAIN_MODEL.md`
- `docs/REALTIME_EVENTS.md`
- `docs/API_CONTRACTS.md`
- `docs/MAP_SCHEMA.md`
- `docs/AVATAR_CUSTOMIZATION.md`
- `docs/ASSET_PIPELINE.md`
- `docs/WEB_ARCHITECTURE.md`
- `docs/BACKEND_ARCHITECTURE.md`
- `docs/TEST_STRATEGY.md`

Critério de aceite:

- Cada arquivo existe com título, objetivo e link/referência para a spec correspondente.

Não fazer ainda:

- Não detalhar implementação além do que já está nas specs.

### ATV-0003 — Criar arquivos de ambiente

Objetivo: definir contratos de configuração local.

Criar/alterar:

- `.env.example`
- `backend/.env.example`
- `web/.env.example`

Critério de aceite:

- Variáveis mínimas documentadas:
  - `DATABASE_URL`
  - `REDIS_URL`
  - `JWT_SECRET`
  - `API_PORT`
  - `WS_PORT`
  - `WEB_API_BASE_URL`
  - `WEB_WS_URL`

Não fazer ainda:

- Não criar `.env` real com segredo.

## Fase 1 — Infra local

### ATV-0101 — Criar Docker Compose local

Objetivo: subir PostgreSQL e Redis para desenvolvimento.

Criar/alterar:

- `docker-compose.yml`
- `infra/postgres/`
- `infra/redis/`

Serviços:

- `postgres`
- `redis`

Critério de aceite:

- `docker compose config` passa.
- PostgreSQL expõe porta `5432`.
- Redis expõe porta `6379`.
- Volumes nomeados existem para dados.

Não fazer ainda:

- Não criar imagem custom do backend.
- Não criar deploy cloud.

### ATV-0102 — Criar healthcheck de infraestrutura

Objetivo: validar que PostgreSQL e Redis estão prontos.

Criar/alterar:

- `scripts/check-infra.sh`

Critério de aceite:

- Script verifica PostgreSQL.
- Script verifica Redis.
- Script retorna erro quando algum serviço estiver indisponível.

Não fazer ainda:

- Não conectar aplicação real.

## Fase 2 — Scaffold backend Fastify

### ATV-0201 — Criar projeto Node/TypeScript no backend

Objetivo: scaffold inicial do backend.

Criar/alterar:

- `backend/package.json`
- `backend/tsconfig.json`
- `backend/src/main.ts`
- `backend/src/app.ts`
- `backend/src/shared/`

Dependências esperadas:

- Fastify.
- TypeScript.
- Zod.
- dotenv/config equivalente.

Critério de aceite:

- `npm run build` compila.
- `npm run dev` inicia servidor.
- `GET /health` retorna status básico.

Não fazer ainda:

- Não implementar auth.
- Não criar banco.

### ATV-0202 — Criar arquitetura shared do backend

Objetivo: criar base DDD reutilizável.

Criar/alterar:

- `backend/src/shared/domain/entity.ts`
- `backend/src/shared/domain/aggregate-root.ts`
- `backend/src/shared/domain/value-object.ts`
- `backend/src/shared/domain/domain-event.ts`
- `backend/src/shared/domain/result.ts`
- `backend/src/shared/application/use-case.ts`
- `backend/src/shared/application/event-bus.ts`
- `backend/src/shared/infrastructure/config/`
- `backend/src/shared/infrastructure/logger/`
- `backend/src/shared/presentation/errors/`
- `backend/src/shared/presentation/middlewares/`

Critério de aceite:

- Tipos base compilam.
- `Result` representa sucesso/erro sem lançar exceção para regra de negócio.
- `DomainEvent` tem nome, aggregateId e occurredAt.

Não fazer ainda:

- Não acoplar shared a Fastify diretamente fora da camada presentation/infrastructure.

### ATV-0203 — Criar módulos DDD vazios do backend

Objetivo: criar diretórios dos bounded contexts.

Criar/alterar:

- `backend/src/modules/identity/`
- `backend/src/modules/workspace/`
- `backend/src/modules/presence/`
- `backend/src/modules/interaction/`
- `backend/src/modules/communication/`
- `backend/src/modules/meeting/`
- `backend/src/modules/avatar/`
- `backend/src/modules/notification/`
- `backend/src/modules/asset/`
- `backend/src/modules/billing/`

Dentro de cada módulo:

- `domain/entities/`
- `domain/value-objects/`
- `domain/events/`
- `domain/services/`
- `domain/repositories/`
- `application/use-cases/`
- `application/commands/`
- `application/queries/`
- `application/ports/`
- `infrastructure/persistence/`
- `infrastructure/mappers/`
- `presentation/http/`
- `presentation/schemas/`

Critério de aceite:

- Estrutura existe para todos os módulos.
- Cada módulo tem `index.ts` ou barrel equivalente quando fizer sentido.

Não fazer ainda:

- Não criar entidades concretas nesta atividade.

### ATV-0204 — Criar camada de configuração backend

Objetivo: carregar e validar env vars.

Criar/alterar:

- `backend/src/shared/infrastructure/config/env.ts`
- `backend/src/shared/infrastructure/config/config.ts`

Critério de aceite:

- Env é validado com schema.
- App falha ao iniciar se variável obrigatória faltar.

Não fazer ainda:

- Não conectar banco.

### ATV-0205 — Criar Prisma ou Drizzle

Objetivo: configurar ORM escolhido para PostgreSQL.

Criar/alterar:

- Se Prisma:
  - `backend/prisma/schema.prisma`
  - `backend/src/shared/infrastructure/database/prisma-client.ts`
- Se Drizzle:
  - `backend/src/shared/infrastructure/database/schema/`
  - `backend/src/shared/infrastructure/database/client.ts`

Critério de aceite:

- Cliente de banco compila.
- Script de migration existe.
- Conexão usa `DATABASE_URL`.

Não fazer ainda:

- Não modelar todas as tabelas finais.

### ATV-0206 — Criar WebSocket base

Objetivo: iniciar gateway realtime sem regras de negócio.

Criar/alterar:

- `backend/src/realtime/websocket-server.ts`
- `backend/src/realtime/connection-registry.ts`
- `backend/src/realtime/channels/`
- `backend/src/realtime/events/`
- `backend/src/realtime/serializers/`

Critério de aceite:

- Servidor aceita conexão autenticável em modo placeholder.
- Connection registry registra e remove conexão.
- Evento ping/pong básico funciona.

Não fazer ainda:

- Não implementar movimento.
- Não implementar presença real.

## Fase 3 — Scaffold web Flutter Web

### ATV-0301 — Criar projeto Flutter Web

Objetivo: scaffold inicial do web.

Criar/alterar:

- `web/pubspec.yaml`
- `web/lib/main.dart`
- `web/lib/app.dart`
- `web/test/`
- `web/assets/`

Dependências esperadas:

- Riverpod ou Bloc.
- GoRouter.
- Dio.
- WebSocket client.
- Flame ou engine/canvas própria.

Critério de aceite:

- `flutter test` executa.
- `flutter run -d chrome` abre app inicial.

Não fazer ainda:

- Não implementar mapa.

## Fase 3.5 — Assets mínimos antes do web visual

### ATV-0351 — Definir asset pack inicial

Objetivo: criar o pacote visual mínimo que o renderer vai consumir.

Specs relacionadas:

- `08-asset-prerequisites-spec.md`
- `47-asset-pipeline-visual-spec.md`
- `50-sprite-slicing-atlas-spec.md`
- `51-character-sprite-generation-spec.md`

Criar/alterar:

- `web/assets/sprites/`
- `web/assets/tilesets/`
- `web/assets/furniture/`
- `web/assets/maps/`
- `web/assets/atlases/`

Critério de aceite:

- Pastas existem.
- Asset pack inicial tem ID e versão.
- `pubspec.yaml` registra assets quando o web já existir.

Não fazer ainda:

- Não implementar renderer.

### ATV-0352 — Criar ou recortar personagem padrão

Objetivo: garantir que o app tenha avatar antes do renderer.

Criar/alterar:

- `web/assets/sprites/characters/character-01/`
- `web/assets/sprites/characters/characters.json`

Critério de aceite:

- `character-01` tem 12 sprites obrigatórios.
- Sprites têm fundo transparente.
- Metadata define hitbox e frames.

Não fazer ainda:

- Não implementar customizador.

### ATV-0353 — Criar ou recortar personagens MVP

Objetivo: completar o conjunto mínimo de 8 personagens.

Criar/alterar:

- `web/assets/sprites/characters/character-02/`
- `web/assets/sprites/characters/character-03/`
- `web/assets/sprites/characters/character-04/`
- `web/assets/sprites/characters/character-05/`
- `web/assets/sprites/characters/character-06/`
- `web/assets/sprites/characters/character-07/`
- `web/assets/sprites/characters/character-08/`
- `web/assets/sprites/characters/characters.json`

Critério de aceite:

- Existem 8 personagens.
- Cada personagem tem 12 sprites obrigatórios.
- Todos estão referenciados no metadata.

### ATV-0354 — Criar tiles e móveis mínimos

Objetivo: garantir assets para mapa inicial.

Criar/alterar:

- `web/assets/tilesets/`
- `web/assets/furniture/`

Critério de aceite:

- Existem piso, parede, porta, janela, mesa, cadeira, mesa de reunião, planta e sofá.
- Objetos bloqueantes têm collision mask documentada.

### ATV-0355 — Criar ícones, balões, gestos e reações mínimos

Objetivo: garantir assets sociais antes de toolbar e balões.

Criar/alterar:

- `web/assets/sprites/gestures/`
- `web/assets/sprites/bubbles/`
- `web/assets/sprites/reactions/`
- `web/assets/atlases/` se usar atlas.

Critério de aceite:

- Existem assets para typing, call, knock, coffee, wave, shout, help e chat.
- Metadata de atlas existe se os assets forem agrupados.

### ATV-0302 — Criar arquitetura base do web

Objetivo: criar diretórios por camadas/features.

Criar/alterar:

- `web/lib/core/config/`
- `web/lib/core/theme/`
- `web/lib/core/router/`
- `web/lib/core/network/`
- `web/lib/core/realtime/`
- `web/lib/core/storage/`
- `web/lib/core/errors/`
- `web/lib/core/utils/`
- `web/lib/features/auth/`
- `web/lib/features/workspace/`
- `web/lib/features/avatar/`
- `web/lib/features/chat/`
- `web/lib/features/meeting/`
- `web/lib/features/presence/`
- `web/lib/features/interaction/`
- `web/lib/features/notification/`
- `web/lib/features/admin/`
- `web/lib/shared/widgets/`
- `web/lib/shared/design_system/`
- `web/lib/shared/pixel_assets/`
- `web/lib/shared/extensions/`

Dentro de cada feature:

- `domain/`
- `application/`
- `data/`
- `presentation/`

Critério de aceite:

- Diretórios existem.
- Estrutura segue o `PLAN_ESCRITORIO_VIRTUAL_DDD.md`.

Não fazer ainda:

- Não criar widgets finais.

### ATV-0303 — Criar design system Flutter light/dark

Objetivo: implementar tokens do tema.

Criar/alterar:

- `web/lib/core/theme/app_theme.dart`
- `web/lib/core/theme/app_colors.dart`
- `web/lib/core/theme/app_spacing.dart`
- `web/lib/core/theme/app_radius.dart`
- `web/lib/shared/design_system/`

Critério de aceite:

- App suporta light e dark mode.
- Tokens batem com `02-theme-layout-spec.md`.
- Nenhuma tela usa cor hardcoded fora dos tokens, exceto exceção justificada.

Não fazer ainda:

- Não criar mapa nem chat.

### ATV-0304 — Criar roteamento inicial

Objetivo: definir rotas principais.

Criar/alterar:

- `web/lib/core/router/app_router.dart`
- Telas placeholder:
  - `login`
  - `organizationSelection`
  - `workspaceSelection`
  - `office`

Critério de aceite:

- Navegação entre placeholders funciona.
- Rotas têm nomes estáveis.

Não fazer ainda:

- Não implementar autenticação real.

## Fase 4 — Banco e domínio Identity

### ATV-0401 — Criar schema inicial Identity

Objetivo: modelar usuário, organização, membership e convite.

Criar/alterar:

- Schema/tabelas:
  - `users`
  - `organizations`
  - `memberships`
  - `invitations`

Critério de aceite:

- Migration roda.
- Constraints de email único e relações existem.

Não fazer ainda:

- Não criar workspaces.

### ATV-0402 — Implementar domínio Identity

Objetivo: criar entidades e value objects.

Criar/alterar:

- `User`
- `Organization`
- `Membership`
- `Invitation`
- `Email`
- `DisplayName`
- `OrganizationName`
- `RoleName`
- Eventos Identity.

Critério de aceite:

- Testes unitários cobrem criação válida e inválida.
- Regras ficam no domínio.

Não fazer ainda:

- Não criar controllers.

### ATV-0403 — Implementar use cases de auth e organização

Objetivo: criar casos de uso principais.

Criar/alterar:

- `RegisterUserUseCase`
- `LoginUserUseCase`
- `CreateOrganizationUseCase`
- `InviteMemberUseCase`
- `AcceptInvitationUseCase`

Critério de aceite:

- Use cases têm testes.
- Portas de hash/token/repository ficam abstraídas.

Não fazer ainda:

- Não expor REST antes dos schemas.

### ATV-0404 — Criar REST Identity

Objetivo: expor endpoints de auth/org.

Criar/alterar:

- Rotas HTTP.
- Schemas Zod.
- Mappers DTO.

Endpoints:

- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/logout`
- `GET /auth/me`
- `POST /organizations`
- `GET /organizations`
- `POST /organizations/:id/invitations`
- `POST /invitations/:token/accept`

Critério de aceite:

- Endpoints validam payload.
- Erros retornam formato consistente.
- Testes de integração básicos passam.

## Fase 5 — Workspace e mapa estático

### ATV-0501 — Criar schema Workspace

Objetivo: modelar escritórios, andares, mapas, salas e mesas.

Criar/alterar:

- `workspaces`
- `floors`
- `maps`
- `rooms`
- `desks`

Critério de aceite:

- Migration roda.
- Relações com organização e floor existem.

### ATV-0502 — Implementar domínio Workspace

Objetivo: criar agregados e regras de mapa.

Criar/alterar:

- `WorkspaceAggregate`
- `FloorAggregate`
- `RoomAggregate`
- `DeskAggregate`
- Value objects de coordenada, tamanho e colisão.

Critério de aceite:

- Testes impedem mesa/sala fora do mapa.
- Testes validam workspace com mapa ativo.

### ATV-0503 — Criar mapa mockado inicial

Objetivo: ter um mapa JSON renderizável.

Criar/alterar:

- `web/assets/maps/office-default.json`
- `web/assets/tilesets/`
- `web/assets/furniture/`

Critério de aceite:

- JSON segue `06-map-assets-avatar-spec.md`.
- Asset paths estão registrados no `pubspec.yaml`.

### ATV-0504 — Criar endpoints de workspace/mapa

Objetivo: entregar mapa ao web.

Endpoints:

- `POST /organizations/:organizationId/workspaces`
- `GET /organizations/:organizationId/workspaces`
- `GET /workspaces/:workspaceId`
- `GET /workspaces/:workspaceId/map`

Critério de aceite:

- Endpoint de mapa retorna floor, layers, desks, rooms e zones.

### ATV-0505 — Renderizar mapa estático no web

Objetivo: exibir mapa em camadas.

Criar/alterar:

- `web/lib/features/workspace/presentation/game/office_canvas.dart`
- `map_renderer.dart`
- `tile_renderer.dart`

Critério de aceite:

- Mapa aparece no office.
- Camadas renderizam na ordem correta.
- Light/dark não quebra leitura do mapa.

Não fazer ainda:

- Não implementar movimento.

## Fase 6 — Avatar local e movimento

### ATV-0601 — Criar modelo de avatar padrão no web

Objetivo: carregar o personagem padrão já criado na fase `3.5` e modelar o avatar inicial no web.

Criar/alterar:

- `web/lib/features/avatar/domain/`
- loader de `web/assets/sprites/characters/characters.json`

Critério de aceite:

- Avatar padrão é carregado via `characters.json`.
- Frames idle e walking existem conforme metadata.
- Fallback visual existe.

### ATV-0602 — Renderizar avatar local

Objetivo: mostrar avatar do usuário no mapa.

Criar/alterar:

- `avatar_renderer.dart`
- `animation_controller.dart`

Critério de aceite:

- Avatar aparece na posição inicial.
- Nome e indicador de presença aparecem.

### ATV-0603 — Movimento por teclado

Objetivo: controlar avatar local.

Criar/alterar:

- Input handler.
- Validação de colisão no client.

Critério de aceite:

- W/A/S/D e setas funcionam.
- Avatar não atravessa colisão.
- Estado idle/walk muda conforme direção.

### ATV-0604 — Movimento por clique

Objetivo: permitir clique para destino em fase posterior, se viável.

Critério de aceite:

- Se implementado, respeita colisão.
- Se adiado, registrar decisão em ADR.

## Fase 7 — Presença realtime

### ATV-0701 — Criar schema de sessões de presença

Objetivo: persistir ou rastrear sessão atual.

Criar/alterar:

- `presence_sessions`
- Redis keys para presença efêmera.

Critério de aceite:

- Sessão tem user, workspace, floor, connectionId, status, posição e lastSeen.

### ATV-0702 — Implementar domínio Presence

Objetivo: regras de entrada, saída, movimento e status.

Criar/alterar:

- `AvatarPresenceAggregate`
- `Position`
- `Direction`
- `PresenceStatus`
- Eventos Presence.

Critério de aceite:

- Testes validam movimento e status.

### ATV-0703 — Implementar eventos WebSocket de workspace

Objetivo: entrar e sair do escritório.

Eventos:

- `workspace:join`
- `workspace:leave`
- `workspace:user.joined`
- `workspace:user.left`

Critério de aceite:

- Dois clients recebem entrada/saída um do outro.

### ATV-0704 — Implementar movimento realtime

Objetivo: sincronizar avatares.

Eventos:

- `avatar:move`
- `avatar:stop`
- `avatar:moved`

Critério de aceite:

- Movimento de um usuário aparece no outro.
- Backend valida posição.
- Web interpola avatar remoto.

### ATV-0705 — Implementar status de presença

Objetivo: status manual e automático.

Eventos:

- `presence:status.change`
- `presence:status.changed`

Critério de aceite:

- Status muda no avatar.
- Away automático funciona por timeout.

## Fase 7.5 — WebRTC Proximidade (Áudio e Vídeo)

Spec de referência: `todo/30-webrtc-proximity-spec.md`.

### ATV-0750 — Criar relay WebRTC no backend (signaling server)

Objetivo: encaminhar mensagens de sinalização WebRTC entre peers via WebSocket sem interpretar conteúdo.

Criar/alterar:

- `backend/src/realtime/events/room-events.ts` — adicionar handlers para eventos `webrtc:*`
- Handler `webrtc:offer`: valida que ambos os usuários estão no mesmo floor → encaminha ao `targetUserId`
- Handler `webrtc:answer`: relay para `fromUserId`
- Handler `webrtc:ice-candidate`: relay para `targetUserId`
- Handler `webrtc:hangup`: relay para `targetUserId`
- Cleanup no disconnect: emitir `webrtc:hangup` para todos os peers da sessão

Critério de aceite:

- Evento `webrtc:offer` enviado por A chega em B como `webrtc:offer` com `fromUserId = A`.
- Backend rejeita relay se usuários estiverem em floors diferentes.
- Disconnect emite `webrtc:hangup` automaticamente.

Não fazer ainda:

- Não implementar TURN server.
- Não fazer lógica de proximidade no backend.

### ATV-0751 — Implementar detecção de proximidade avatar→avatar no client

Objetivo: calcular distância entre o avatar local e avatares remotos a cada update de posição e emitir eventos internos de enter/leave.

Criar/alterar:

- `web/lib/features/workspace/presentation/game/proximity_detector.dart`
- `web/lib/features/avatar/presentation/presence_provider.dart` — raio configurável

Lógica:

```
distância = sqrt((ax - bx)² + (ay - by)²)
se distância <= raio && não estava próximo → proximityEnter(userId)
se distância > raio  && estava próximo    → proximityLeave(userId)
```

Critério de aceite:

- `proximityEnter` dispara ao cruzar o raio.
- `proximityLeave` dispara ao sair do raio.
- Não dispara múltiplos eventos redundantes para o mesmo peer.
- Raio padrão de `4 tiles`.

### ATV-0752 — Implementar WebRTC peer connection no Flutter Web

Objetivo: criar e gerenciar `RTCPeerConnection` por par de usuários próximos.

Criar/alterar:

- `web/lib/features/workspace/data/webrtc_service.dart`
- `web/lib/features/workspace/presentation/proximity_provider.dart`

Dependência: `flutter_webrtc` em `pubspec.yaml`.

Fluxo:

- `proximityEnter` → se `userId < peerId` (sort) → criar peer → enviar `webrtc:offer`
- Receber `webrtc:offer` → criar peer → enviar `webrtc:answer`
- Trocar ICE candidates até conexão estabelecida
- `proximityLeave` → `webrtc:hangup` → fechar peer connection

Critério de aceite:

- Dois usuários no mesmo floor dentro do raio ouvem e veem um ao outro.
- Sair do raio encerra a conexão.
- Máximo de 8 peer connections simultâneas; excesso é ignorado com log.

### ATV-0753 — Implementar áudio espacial por distância

Objetivo: ajustar volume de cada peer proporcionalmente à distância dentro do raio.

Criar/alterar:

- `web/lib/features/workspace/data/spatial_audio_service.dart`

Lógica:

```
volume = max(0.0, 1.0 - distância / raioMaximo)
gainNode.gain.value = volume
```

Critério de aceite:

- Volume diminui conforme avatar se afasta.
- Volume é `1.0` quando sobrepostos, `0.0` na borda do raio.
- Atualiza em tempo real a cada `avatar:moved`.

### ATV-0754 — Criar UI de vídeo de proximidade e controles de mídia

Objetivo: exibir miniaturas de peers próximos e permitir mudo/câmera na toolbar.

Criar/alterar:

- `web/lib/features/workspace/presentation/proximity_video_overlay.dart`
- `web/lib/shared/widgets/media_control_bar.dart`
- `web/lib/features/workspace/presentation/office_page.dart` — integrar overlay

Componentes:

- `ProximityVideoOverlay`: grade 2×2 no canto superior direito; avatar sem câmera exibe inicial do nome.
- `MediaControlBar`: botões de mudo (microfone) e câmera; estado ativo/inativo.

Critério de aceite:

- Miniatura do peer aparece ao conectar, some ao desconectar.
- Botão de mudo silencia microfone local sem encerrar peer connection.
- Botão de câmera desliga vídeo local; peer vê placeholder.
- Permissão de câmera/mic negada → app continua sem AV, sem crash.

### ATV-0755 — Modo Spotlight em salas de reunião

Objetivo: ao entrar em `MeetingRoom`, conectar com todos os participantes independente de distância.

Criar/alterar:

- `web/lib/features/workspace/data/webrtc_service.dart` — modo spotlight
- `web/lib/features/workspace/presentation/proximity_provider.dart` — desativar raio em sala

Critério de aceite:

- Entrar em sala → peer connections com todos os participantes.
- Sair da sala → encerrar peer connections de sala, retornar ao modo proximidade.
- Modo spotlight não conflita com peer connections de proximidade preexistentes.

---

## Fase 8 — Mesas e proximidade

### ATV-0801 — Implementar proximidade com mesa

Objetivo: detectar mesa próxima.

Eventos:

- `proximity:desk.detected`
- `proximity:lost`

Critério de aceite:

- Card de mesa aparece dentro do raio.
- Card desaparece fora do raio.

### ATV-0802 — Criar DeskComponent no web

Objetivo: renderizar estados de mesa.

Estados:

- `unassigned`
- `assignedAvailable`
- `assignedAway`
- `assignedBusy`
- `ownerAtDesk`
- `hasUnreadNotes`
- `beingKnocked`
- `callPending`

Critério de aceite:

- Estados visuais seguem `03-component-animation-spec.md`.

### ATV-0803 — Implementar bater na mesa

Objetivo: ação social leve.

Eventos:

- `desk:knock`
- `DeskKnocked`
- `bubble:show`

Critério de aceite:

- Mesa faz shake.
- Dono recebe notificação leve.

### ATV-0804 — Implementar chamar dono da mesa

Objetivo: convite realtime.

Eventos:

- `call:invite`
- `interaction:received`
- `notification:created`

Critério de aceite:

- Destinatário vê toast e balão.
- Convite expira.

### ATV-0805 — Implementar recado de mesa

Objetivo: mensagem persistente na mesa.

Criar/alterar:

- `desk_notes`
- Use case `CreateDeskNoteUseCase`
- Endpoint/evento de recado.

Critério de aceite:

- Recado salva no banco.
- Dono consegue listar e marcar como lido.

## Fase 9 — Salas e chat

### ATV-0901 — Implementar entrada e saída de sala

Eventos:

- `room:enter`
- `room:leave`
- `RoomEntered`
- `RoomLeft`

Critério de aceite:

- Usuário entra no canal da sala.
- Status muda para `InMeeting` quando aplicável.

### ATV-0902 — Criar RoomComponent no web

Objetivo: renderizar estado da sala.

Estados:

- `empty`
- `occupied`
- `meetingActive`
- `locked`
- `focus`

Critério de aceite:

- Indicadores visuais aparecem corretamente.

### ATV-0903 — Criar schema de chat

Criar/alterar:

- `conversations`
- `messages`

Critério de aceite:

- Mensagens têm canal, sender, content, status e timestamps.

### ATV-0904 — Implementar chat de sala

Eventos/endpoints:

- `chat:message.send`
- `GET /rooms/:roomId/messages`

Critério de aceite:

- Participantes da sala enviam e recebem mensagens.
- Histórico carrega ao abrir sala.

### ATV-0905 — Implementar typing indicator

Eventos:

- `chat:typing.start`
- `chat:typing.stop`
- `bubble:show`
- `bubble:hide`

Critério de aceite:

- Balão de três pontos aparece acima do avatar.
- Typing expira e não persiste.

## Fase 10 — Gestos, reações e toolbar

### ATV-1001 — Criar ícones e toolbar de ações

Objetivo: toolbar inferior com ações MVP.

Criar/alterar:

- `BottomActionToolbar`
- Assets de ícones.

Critério de aceite:

- Toolbar segue tema light/dark.
- Botões têm tooltip e estado disabled/active.

### ATV-1002 — Implementar InteractionBubble

Objetivo: balões animados por prioridade.

Critério de aceite:

- Tipos e prioridades seguem `03-component-animation-spec.md`.
- Fila de balões não sobrepõe nome do avatar.

### ATV-1003 — Implementar gesto acenar

Critério de aceite:

- Wave dura `2s`.
- É propagado para usuários no escopo correto.

### ATV-1004 — Implementar gesto gritar

Critério de aceite:

- Shout alcança raio maior.
- Animação dura `3s`.

### ATV-1005 — Implementar convite café

Critério de aceite:

- Convite aparece com balão de café.
- Pode expirar.

### ATV-1006 — Implementar pedir ajuda

Critério de aceite:

- Help gera notificação e balão.
- Prioridade maior que reação simples.

### ATV-1007 — Implementar reações sociais básicas

Reações:

- Gostei.
- Ideia.
- Alerta.
- Celebração.
- Check.

Critério de aceite:

- Reações aparecem, flutuam e somem sem alterar layout.

## Fase 11 — Customização de avatar

### ATV-1101 — Criar schema Avatar

Criar/alterar:

- `avatar_profiles`

Critério de aceite:

- Perfil referencia skin, hair, face, clothing, shoes e accessories.

### ATV-1102 — Implementar domínio Avatar Customization

Critério de aceite:

- Combinação inválida usa fallback.
- Testes cobrem asset incompatível.

### ATV-1103 — Criar AvatarCustomizer

Critério de aceite:

- Usuário altera pele, cabelo, roupa e acessórios.
- Preview usa camadas corretas.

### ATV-1104 — Criar endpoints Avatar

Endpoints:

- `GET /avatar/me`
- `PATCH /avatar/me`
- `GET /avatar/cosmetics`
- `POST /avatar/preview`

Critério de aceite:

- Customização salva e recarrega.

## Fase 12 — Admin MVP

### ATV-1201 — Criar tela admin de membros

Critério de aceite:

- Admin lista membros e status.

### ATV-1202 — Criar ação de atribuir mesa

Critério de aceite:

- Admin associa mesa a membro.
- Mesa atualiza dono no mapa.

### ATV-1203 — Criar cadastro simples de sala

Critério de aceite:

- Admin cria sala com nome, tipo, capacidade e posição.

### ATV-1204 — Criar publicação de mapa por JSON

Critério de aceite:

- Admin envia JSON.
- Backend valida schema, limites e colisões.
- Mapa publicado fica versionado.

## Fase 13 — Qualidade e fechamento do MVP

### ATV-1301 — Testes unitários mínimos por domínio

Critério de aceite:

- Identity, Workspace, Presence, Interaction e Communication têm testes.

### ATV-1302 — Testes de integração REST

Critério de aceite:

- Auth, organizations, workspace/map, desks, rooms e chat testados.

### ATV-1303 — Testes de integração WebSocket

Critério de aceite:

- Join/leave, movement, status, typing, interaction e notification testados.

### ATV-1304 — Revisão visual light/dark

Critério de aceite:

- Escritório, toolbar, chat, cards, balões, mesas e salas funcionam nos dois temas.

### ATV-1305 — Revisão de animações

Critério de aceite:

- Todas as animações MVP batem com `03-component-animation-spec.md`.
- `prefers-reduced-motion` é respeitado.

### ATV-1306 — E2E do MVP

Fluxo:

1. Usuário A e B entram no escritório.
2. A vê B.
3. A anda até mesa de B.
4. A chama B.
5. B recebe notificação.
6. A deixa recado.
7. B lê recado.
8. A entra em sala.
9. B vê status de A.
10. A envia mensagem no chat da sala.
11. Typing bubble aparece.
12. A envia gesto/reação.

Critério de aceite:

- Fluxo completo passa sem erro crítico.

## Regra de execução para agentes

Ao implementar:

1. Escolher a próxima ATV ainda não concluída.
2. Ler specs relacionadas.
3. Explicar plano curto.
4. Alterar apenas arquivos da ATV.
5. Rodar verificação possível.
6. Registrar no resumo final o número da ATV concluída.
7. Não avançar para a próxima ATV sem pedido explícito ou sem terminar a atual.
