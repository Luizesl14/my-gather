# PLAN.md — Escritório Virtual Interativo com Avatares, Salas, Mesas, Chat, Chamadas e Ações Sociais

> Produto inspirado na experiência de escritório virtual estilo Gather, mas com identidade própria: um ambiente digital onde usuários entram com avatar, caminham pelo mapa, acessam salas de reunião, visitam mesas de colegas, chamam para conversa, deixam mensagens, fazem gestos, reações e interações sociais em tempo real.

---

## 1. Visão do Produto

### 1.1 Nome provisório

- Atom Office
- Orbit Office
- Mesa Virtual
- WorkVerse
- Escritório Vivo

### 1.2 Frase do produto

> Um escritório virtual 2D onde pessoas trabalham, se encontram, chamam colegas, entram em salas, conversam e deixam mensagens como se estivessem em um ambiente físico.

### 1.3 Problema que o produto resolve

Times remotos ou híbridos perdem parte da presença natural de um escritório físico:

- Não sabem quem está disponível.
- Não conseguem “ir até a mesa” de alguém.
- Tudo vira reunião formal.
- Falta espontaneidade.
- Faltam sinais visuais de presença.
- A comunicação fica espalhada em chat, calendário, chamadas e ferramentas separadas.
- Novos membros não sentem o ambiente da empresa.

### 1.4 Solução proposta

Criar um escritório virtual com:

- Mapa 2D navegável.
- Avatares personalizados.
- Mesas individuais.
- Salas de reunião.
- Áreas comuns.
- Presença em tempo real.
- Chat por proximidade, mesa, sala e organização.
- Chamadas de áudio/vídeo por convite.
- Mensagem assíncrona na mesa do colega.
- Gestos e reações visuais.
- Balões animados de digitação, fala e interação.
- Ferramentas sociais: acenar, chamar, gritar, pedir ajuda, convidar para café, chamar para reunião.
- Futuramente: agentes de IA por sala, resumo de conversas, memória do ambiente e onboarding.

---

## 2. Objetivos do MVP

### 2.1 Objetivo principal

Construir a primeira versão funcional do escritório virtual onde usuários conseguem:

1. Criar conta.
2. Entrar em uma organização.
3. Entrar em um escritório virtual.
4. Ver o mapa 2D.
5. Controlar seu avatar.
6. Ver outros usuários online no mapa.
7. Ir até a mesa de outro usuário.
8. Chamar esse usuário.
9. Deixar mensagem na mesa caso ele esteja ocupado ou ausente.
10. Entrar em sala de reunião.
11. Ver quem está na sala.
12. Conversar por chat.
13. Exibir balões animados de ação: digitando, falando, chamando, acenando.
14. Usar ações rápidas: acenar, chamar, gritar, café, reunião, ajuda.

### 2.2 Fora do MVP inicial

Para não travar o projeto cedo demais, deixar para fases futuras:

- Áudio espacial completo.
- Vídeo nativo WebRTC completo.
- Editor visual avançado de mapa.
- Marketplace de mapas.
- IA completa por sala.
- Gravação/transcrição de reunião.
- Aplicativo mobile Flutter nativo.
- Sistema de billing completo.
- Whiteboard colaborativo completo.

### 2.3 Estratégia de entrega

Fazer em camadas:

1. **MVP 0 — Fundacional:** login, organização, escritório, mapa estático.
2. **MVP 1 — Presença:** avatar andando e outros usuários em tempo real.
3. **MVP 2 — Interação social:** chamar colega, deixar mensagem, gestos, balões.
4. **MVP 3 — Salas:** entrar/sair de sala, chat por sala, status de reunião.
5. **MVP 4 — Chamadas:** integração inicial com chamada externa ou sala WebRTC simples.
6. **MVP 5 — Customização:** avatar, cabelo, roupa, pele, acessórios.
7. **MVP 6 — Admin:** criar salas, mesas, permissões básicas.

---

## 3. Linguagem Ubíqua

Este vocabulário deve ser usado no código, no domínio, nos eventos, nas APIs e nas telas.

| Termo | Significado |
|---|---|
| Organização | Empresa, comunidade ou grupo dono de um escritório virtual. |
| Escritório | Ambiente virtual principal da organização. |
| Andar | Divisão lógica ou visual de um escritório. Pode conter salas e mesas. |
| Mapa | Representação 2D navegável do escritório. |
| Tile | Unidade do mapa, usada para piso, parede, obstáculo ou zona interativa. |
| Avatar | Representação visual do usuário no escritório. |
| Mesa | Local fixo ou reservado de um membro dentro do escritório. |
| Sala | Espaço virtual onde usuários podem entrar para reunião ou conversa. |
| Área comum | Espaço aberto do mapa, como recepção, copa, corredor ou lounge. |
| Presença | Estado atual do usuário: online, ausente, ocupado, em reunião, focado. |
| Posição | Coordenada do avatar no mapa. |
| Proximidade | Relação espacial entre dois avatares ou entre avatar e objeto. |
| Interação | Ação executada por um usuário em outro usuário, mesa, sala ou objeto. |
| Chamada | Convite para conversa síncrona. Pode virar áudio/vídeo. |
| Recado | Mensagem deixada na mesa de um usuário. |
| Balão | Indicador visual acima do avatar ou objeto: digitando, falando, chamando. |
| Gesto | Ação visual rápida: acenar, levantar mão, apontar, bater palma. |
| Reação | Emoji/ícone social: café, ajuda, ideia, gostei, alerta, grito. |
| Sessão | Conexão ativa do usuário no escritório. |
| Canal | Espaço de comunicação: global, sala, mesa, proximidade ou privado. |
| Zona Interativa | Região do mapa que dispara ação: entrar em sala, sentar na mesa, abrir painel. |

---

## 4. DDD — Classificação de Subdomínios

## 4.1 Subdomínio Principal / Core Domain

O Core Domain é aquilo que torna o produto especial e diferencia o negócio.

### 4.1.1 Virtual Workspace Experience

Responsável pela experiência viva do escritório:

- Escritório virtual.
- Mapa navegável.
- Avatares em tempo real.
- Movimento.
- Proximidade.
- Mesas.
- Salas.
- Interações no ambiente.
- Balões animados.
- Ações sociais.
- Chamadas contextuais.

Este é o coração do produto.

### 4.1.2 Principais capacidades do Core Domain

- Usuário entra no escritório.
- Avatar aparece no mapa.
- Avatar se move.
- Outros usuários veem o movimento em tempo real.
- Usuário se aproxima da mesa de alguém.
- Sistema detecta proximidade.
- Sistema exibe ações disponíveis.
- Usuário chama colega.
- Colega recebe notificação visual.
- Caso colega não responda, usuário deixa recado.
- Usuário entra em sala de reunião.
- Sistema muda status para “em reunião”.
- Balões animados indicam digitação, fala, chamada, reação ou gesto.

---

## 4.2 Subdomínios de Suporte / Supporting Domains

São importantes para o produto funcionar, mas não são o principal diferencial isoladamente.

### 4.2.1 Identity & Access

Responsável por:

- Cadastro.
- Login.
- Autenticação.
- Usuário.
- Organização.
- Membros.
- Convites.
- Papéis.
- Permissões.

### 4.2.2 Communication

Responsável por:

- Chat global.
- Chat por sala.
- Chat privado.
- Recados na mesa.
- Convites para chamada.
- Histórico de mensagens.
- Indicadores de digitação.

### 4.2.3 Meeting Management

Responsável por:

- Salas de reunião.
- Entrada e saída de participantes.
- Estado da reunião.
- Convite para reunião.
- Link de reunião externa na fase inicial.
- Integração futura com WebRTC/LiveKit.

### 4.2.4 Avatar Customization

Responsável por:

- Cor de pele.
- Cabelo.
- Cor do cabelo.
- Roupa.
- Calça/saia.
- Sapatos.
- Acessórios.
- Gestos disponíveis.
- Aparência pública.

### 4.2.5 Notification

Responsável por:

- Notificações em tempo real.
- Ping visual.
- Convite recebido.
- Chamada recebida.
- Recado deixado.
- Alerta de sala.
- Badge/contador.

### 4.2.6 Asset Management

Responsável por:

- Sprites.
- Tilesets.
- Objetos do mapa.
- Móveis.
- Animações.
- Versão dos assets.
- Referências de imagem.

### 4.2.7 Administration

Responsável por:

- Criar escritório.
- Configurar salas.
- Vincular mesas aos usuários.
- Definir permissões.
- Configurar mapa inicial.
- Gerenciar membros.

---

## 4.3 Subdomínios Genéricos / Generic Domains

São domínios comuns, que podem ser implementados com bibliotecas ou soluções prontas.

### 4.3.1 Billing

- Planos.
- Assinatura.
- Pagamento.
- Limite de membros.
- Uso mensal.

Pode ser integrado com Stripe, Mercado Pago, Pagar.me etc.

### 4.3.2 File Storage

- Upload de imagem.
- Foto de perfil.
- Assets customizados.
- Ícones.
- Anexos de recados.

Pode usar S3, Cloudflare R2, Supabase Storage ou MinIO.

### 4.3.3 Email Delivery

- Convite por email.
- Recuperação de senha.
- Notificação assíncrona.

Pode usar Resend, SendGrid, SES etc.

### 4.3.4 Audit Log

- Registrar ações importantes.
- Login.
- Mudança de permissão.
- Alteração de mapa.
- Administração de usuários.

### 4.3.5 Observability

- Logs.
- Métricas.
- Tracing.
- Monitoramento de WebSocket.
- Erros do front.

---

## 5. Bounded Contexts

## 5.1 Identity Context

### Responsabilidade

Gerenciar identidade dos usuários, organizações e permissões.

### Entidades

- User
- Organization
- Membership
- Role
- Invitation

### Value Objects

- Email
- PasswordHash
- DisplayName
- OrganizationName
- RoleName
- InvitationToken

### Agregados

#### User Aggregate

Root: `User`

Responsável por:

- Criar usuário.
- Atualizar perfil básico.
- Validar email.
- Ativar/desativar conta.

#### Organization Aggregate

Root: `Organization`

Responsável por:

- Criar organização.
- Adicionar membro.
- Remover membro.
- Alterar papel de membro.
- Criar convite.

### Eventos de domínio

- UserRegistered
- UserProfileUpdated
- OrganizationCreated
- MemberJoinedOrganization
- MemberRemovedFromOrganization
- InvitationCreated
- InvitationAccepted

### Casos de uso

- RegisterUserUseCase
- LoginUserUseCase
- CreateOrganizationUseCase
- InviteMemberUseCase
- AcceptInvitationUseCase
- ChangeMemberRoleUseCase

---

## 5.2 Workspace Context — Core

### Responsabilidade

Modelar o escritório virtual, mapa, salas, mesas e zonas interativas.

### Entidades

- Workspace
- Floor
- Room
- Desk
- Map
- MapObject
- InteractiveZone

### Value Objects

- WorkspaceId
- FloorId
- RoomId
- DeskId
- TileCoordinate
- MapSize
- CollisionArea
- ObjectType
- RoomType

### Agregados

#### Workspace Aggregate

Root: `Workspace`

Contém:

- Nome do escritório.
- Organização dona.
- Andares.
- Configuração ativa.

Regras:

- Um escritório pertence a uma organização.
- Um escritório pode ter vários andares.
- Um escritório precisa ter pelo menos um mapa ativo.

#### Floor Aggregate

Root: `Floor`

Contém:

- Mapa.
- Salas.
- Mesas.
- Objetos.
- Zonas interativas.

Regras:

- Uma mesa deve ocupar uma posição válida.
- Uma sala deve ter área válida no mapa.
- Uma zona interativa deve apontar para uma ação.
- Objetos bloqueantes devem gerar colisão.

#### Room Aggregate

Root: `Room`

Contém:

- Nome.
- Tipo.
- Capacidade.
- Área no mapa.
- Política de acesso.
- Estado atual.

Tipos de sala:

- MeetingRoom
- FocusRoom
- Lounge
- CoffeeRoom
- Reception
- PrivateRoom

#### Desk Aggregate

Root: `Desk`

Contém:

- Dono da mesa.
- Localização.
- Estado.
- Recados.
- Permissões de interação.

Regras:

- Uma mesa pode ou não ter dono.
- Um usuário pode ter uma mesa principal.
- Apenas membros autorizados podem deixar recado.
- Ao visitar mesa de colega, ações contextuais aparecem.

### Eventos de domínio

- WorkspaceCreated
- FloorCreated
- MapPublished
- RoomCreated
- RoomUpdated
- RoomEntered
- RoomLeft
- DeskAssigned
- DeskVisited
- DeskMessageLeft
- InteractiveZoneTriggered

### Casos de uso

- CreateWorkspaceUseCase
- CreateFloorUseCase
- PublishMapUseCase
- CreateRoomUseCase
- AssignDeskToMemberUseCase
- VisitDeskUseCase
- LeaveDeskMessageUseCase
- EnterRoomUseCase
- LeaveRoomUseCase
- GetWorkspaceMapUseCase

---

## 5.3 Presence Context — Core

### Responsabilidade

Gerenciar presença online, posição do avatar, movimento e proximidade.

### Entidades

- Session
- AvatarPresence
- AvatarPosition
- ProximityInteraction

### Value Objects

- ConnectionId
- Position
- Direction
- MovementState
- PresenceStatus
- ProximityRadius

### Estados de presença

- Online
- Available
- Away
- Busy
- InMeeting
- Focus
- Offline

### Estados de movimento

- IdleFront
- IdleBack
- IdleLeft
- IdleRight
- WalkingUp
- WalkingDown
- WalkingLeft
- WalkingRight

### Agregados

#### AvatarPresence Aggregate

Root: `AvatarPresence`

Contém:

- Usuário.
- Sessão ativa.
- Escritório atual.
- Andar atual.
- Posição atual.
- Direção.
- Status.
- Última atividade.

Regras:

- Um avatar só pode se mover para posição válida.
- Avatar não atravessa paredes/objetos bloqueantes.
- Movimento deve respeitar limites do mapa.
- A posição deve ser propagada em tempo real.
- Ao entrar em sala, status pode mudar automaticamente.
- Ao ficar parado por tempo configurado, status pode virar Away.

### Eventos de domínio

- UserEnteredWorkspace
- UserLeftWorkspace
- AvatarMoved
- AvatarStopped
- PresenceStatusChanged
- ProximityDetected
- ProximityLost
- UserBecameAway
- UserReturnedAvailable

### Casos de uso

- EnterWorkspaceUseCase
- LeaveWorkspaceUseCase
- MoveAvatarUseCase
- ChangePresenceStatusUseCase
- DetectNearbyUsersUseCase
- DetectNearbyDeskUseCase
- DetectNearbyRoomUseCase

---

## 5.4 Interaction Context — Core

### Responsabilidade

Gerenciar ações sociais e interações entre usuários, mesas, salas e objetos.

### Entidades

- Interaction
- Gesture
- Reaction
- InteractionBubble
- InteractionRequest

### Value Objects

- InteractionType
- GestureType
- ReactionType
- BubbleType
- InteractionTarget
- InteractionDuration

### Tipos de interação

#### Usuário para usuário

- Wave
- CallUser
- InviteToMeeting
- AskForHelp
- ComeHere
- FollowMe
- Shout
- SendCoffeeInvite
- SendReaction

#### Usuário para mesa

- VisitDesk
- LeaveMessage
- KnockDesk
- CallDeskOwner
- RequestAvailability

#### Usuário para sala

- EnterRoom
- LeaveRoom
- InviteToRoom
- RaiseHand
- RequestMeeting

#### Usuário para ambiente

- OpenDoor
- UseElevator
- SitOnChair
- OpenWhiteboard
- OpenScreen
- InteractWithObject

### Agregados

#### Interaction Aggregate

Root: `Interaction`

Contém:

- Autor.
- Alvo.
- Tipo.
- Estado.
- Timestamp.
- Expiração.

Estados:

- Created
- Sent
- Received
- Accepted
- Rejected
- Expired
- Cancelled

Regras:

- Algumas interações exigem proximidade.
- Algumas podem ser remotas.
- Algumas expiram depois de poucos segundos.
- Algumas geram notificação.
- Algumas geram balão animado.
- Algumas geram mensagem persistente.

### Eventos de domínio

- InteractionRequested
- InteractionDelivered
- InteractionAccepted
- InteractionRejected
- InteractionExpired
- GesturePerformed
- ReactionSent
- BubbleDisplayed
- BubbleHidden
- DeskKnocked
- UserCalledFromDesk

### Casos de uso

- SendWaveUseCase
- CallNearbyUserUseCase
- InviteUserToRoomUseCase
- KnockDeskUseCase
- LeaveDeskMessageUseCase
- SendReactionUseCase
- RaiseHandUseCase
- ShoutNearbyUseCase
- DisplayInteractionBubbleUseCase

---

## 5.5 Communication Context — Supporting

### Responsabilidade

Gerenciar mensagens, chats, canais, indicadores de digitação e recados.

### Entidades

- Conversation
- Message
- Channel
- TypingIndicator
- DeskNote

### Value Objects

- MessageContent
- ChannelType
- MessageStatus
- TypingState

### Tipos de canal

- GlobalWorkspaceChannel
- RoomChannel
- PrivateChannel
- DeskChannel
- ProximityChannel

### Agregados

#### Conversation Aggregate

Root: `Conversation`

Contém:

- Participantes.
- Canal.
- Mensagens.
- Estado.

#### DeskNote Aggregate

Root: `DeskNote`

Contém:

- Mesa.
- Autor.
- Destinatário.
- Conteúdo.
- Status de leitura.

### Regras

- Mensagem de sala só aparece para quem está na sala ou tem permissão.
- Recado na mesa persiste mesmo se o dono estiver offline.
- Indicador de digitação não deve ser persistido.
- Balão de três pontinhos é estado efêmero em tempo real.

### Eventos de domínio

- MessageSent
- MessageReceived
- MessageRead
- UserStartedTyping
- UserStoppedTyping
- DeskNoteCreated
- DeskNoteRead

### Casos de uso

- SendMessageUseCase
- GetRoomMessagesUseCase
- SendPrivateMessageUseCase
- StartTypingUseCase
- StopTypingUseCase
- CreateDeskNoteUseCase
- MarkDeskNoteAsReadUseCase

---

## 5.6 Meeting Context — Supporting

### Responsabilidade

Gerenciar salas de reunião, participantes e chamadas.

### Entidades

- MeetingRoom
- MeetingSession
- MeetingParticipant
- CallInvite

### Value Objects

- MeetingStatus
- ParticipantRole
- CallProvider
- ExternalMeetingUrl

### Estados de reunião

- Idle
- Waiting
- Active
- Locked
- Finished

### Estratégia inicial

No MVP, chamada pode ser:

1. Link externo gerado manualmente.
2. Integração Google Meet/Zoom futura.
3. LiveKit ou WebRTC nativo em fase posterior.

### Eventos de domínio

- MeetingStarted
- MeetingEnded
- ParticipantJoinedMeeting
- ParticipantLeftMeeting
- CallInviteSent
- CallInviteAccepted
- CallInviteRejected

### Casos de uso

- StartMeetingUseCase
- EndMeetingUseCase
- JoinMeetingRoomUseCase
- LeaveMeetingRoomUseCase
- SendCallInviteUseCase
- AcceptCallInviteUseCase
- RejectCallInviteUseCase

---

## 5.7 Avatar Customization Context — Supporting

### Responsabilidade

Gerenciar aparência do avatar.

### Entidades

- AvatarProfile
- AvatarOutfit
- CosmeticAsset
- AnimationSet

### Value Objects

- SkinTone
- HairStyle
- HairColor
- FaceStyle
- EyeStyle
- TopClothing
- BottomClothing
- Shoes
- Accessory
- SpriteLayer

### Camadas do avatar

1. Base body.
2. Skin tone.
3. Hair back layer.
4. Face/eyes.
5. Facial hair.
6. Top clothing.
7. Bottom clothing.
8. Shoes.
9. Accessories.
10. Hair front layer.
11. Gesture overlay.
12. Bubble overlay.

### Regras

- Todo avatar deve ter um corpo base.
- Toda combinação deve gerar visual válido.
- Certas roupas podem bloquear acessórios incompatíveis.
- Assets devem ter versão.
- Avatar deve ter sprite para idle e walking.

### Eventos de domínio

- AvatarCreated
- AvatarCustomized
- AvatarOutfitChanged
- CosmeticAssetUnlocked

### Casos de uso

- CreateAvatarProfileUseCase
- UpdateAvatarAppearanceUseCase
- GetAvailableCosmeticsUseCase
- PreviewAvatarUseCase

---

## 5.8 Notification Context — Supporting

### Responsabilidade

Gerenciar notificações visuais, sonoras e persistentes.

### Entidades

- Notification
- NotificationPreference
- NotificationDelivery

### Value Objects

- NotificationType
- NotificationPriority
- NotificationStatus

### Tipos de notificação

- UserCalled
- DeskMessageReceived
- MeetingInviteReceived
- MentionReceived
- HelpRequested
- CoffeeInviteReceived
- SystemAlert

### Eventos de domínio

- NotificationCreated
- NotificationDelivered
- NotificationRead
- NotificationDismissed

### Casos de uso

- CreateNotificationUseCase
- MarkNotificationAsReadUseCase
- GetUserNotificationsUseCase
- UpdateNotificationPreferencesUseCase

---

## 5.9 Asset Context — Supporting

### Responsabilidade

Gerenciar assets visuais do jogo.

### Entidades

- AssetPack
- SpriteAsset
- TilesetAsset
- AnimationAsset
- ObjectAsset

### Value Objects

- AssetType
- AssetPath
- SpriteFrame
- AnimationFrame
- CollisionMask

### Tipos de asset

- CharacterSprite
- HairSprite
- ClothingSprite
- FurnitureSprite
- TileSprite
- WallSprite
- DoorSprite
- GestureIcon
- ReactionIcon
- BubbleSprite

### Eventos de domínio

- AssetPackCreated
- AssetUploaded
- AssetVersionPublished
- AssetDeprecated

---

## 5.10 Billing Context — Generic

### Responsabilidade

Gerenciar planos e cobrança.

### Entidades

- Plan
- Subscription
- Invoice
- Usage

### Planos sugeridos

#### Free

- 1 organização.
- 1 escritório.
- Até 5 usuários.
- Chat e presença básica.

#### Starter

- Até 25 usuários.
- Mesas e salas.
- Customização básica.
- Histórico de mensagens limitado.

#### Pro

- Até 100 usuários.
- Customização avançada.
- Integrações.
- Relatórios.
- Futuramente IA.

#### Enterprise

- SSO.
- Auditoria.
- Permissões avançadas.
- Domínio próprio.
- SLA.

---

## 6. Arquitetura Técnica

## 6.1 Stack escolhida

### Web

- Flutter Web
- Dart
- Flame ou engine própria com Canvas para mapa 2D
- WebSocket client
- Riverpod ou Bloc para estado
- GoRouter para rotas
- Dio para HTTP

### Backend

- Node.js
- TypeScript
- Fastify
- PostgreSQL
- Redis
- WebSocket ou Socket.IO
- Prisma ou Drizzle ORM
- Zod para validação
- JWT para autenticação

### Infra

- Docker
- Docker Compose local
- PostgreSQL
- Redis
- Nginx ou Traefik
- Cloudflare para DNS/proxy
- S3/R2/MinIO para assets

### Realtime

- WebSocket Gateway no backend.
- Redis Pub/Sub para escalar múltiplas instâncias.
- Canal por workspace/floor/room.

---

## 6.2 Visão de alto nível

```txt
Flutter Web Client
  |
  | HTTP REST
  | WebSocket Realtime
  v
Fastify API Gateway
  |
  |-- Identity Module
  |-- Workspace Module
  |-- Presence Module
  |-- Interaction Module
  |-- Communication Module
  |-- Meeting Module
  |-- Avatar Module
  |-- Notification Module
  |
  |-- PostgreSQL
  |-- Redis
  |-- Object Storage
```

---

## 6.3 Comunicação HTTP vs WebSocket

### HTTP REST

Usar para:

- Login.
- Cadastro.
- Buscar escritório.
- Buscar mapa.
- Buscar assets.
- Configurações.
- Histórico de mensagens.
- Administração.

### WebSocket

Usar para:

- Entrar no escritório.
- Movimento do avatar.
- Presença online.
- Indicador de digitação.
- Balões animados.
- Gestos.
- Reações.
- Chamar colega.
- Entrar/sair de sala em tempo real.
- Convites.
- Notificações instantâneas.

---

## 7. Estrutura de Pastas — Backend Fastify + DDD

```txt
backend
├── src
│   ├── main.ts
│   ├── app.ts
│   │
│   ├── modules
│   │   ├── identity
│   │   │   ├── domain
│   │   │   │   ├── entities
│   │   │   │   ├── value-objects
│   │   │   │   ├── events
│   │   │   │   ├── services
│   │   │   │   └── repositories
│   │   │   ├── application
│   │   │   │   ├── use-cases
│   │   │   │   ├── commands
│   │   │   │   ├── queries
│   │   │   │   └── ports
│   │   │   ├── infrastructure
│   │   │   │   ├── persistence
│   │   │   │   ├── auth
│   │   │   │   └── mappers
│   │   │   └── presentation
│   │   │       ├── http
│   │   │       └── schemas
│   │   │
│   │   ├── workspace
│   │   ├── presence
│   │   ├── interaction
│   │   ├── communication
│   │   ├── meeting
│   │   ├── avatar
│   │   ├── notification
│   │   ├── asset
│   │   └── billing
│   │
│   ├── shared
│   │   ├── domain
│   │   │   ├── entity.ts
│   │   │   ├── aggregate-root.ts
│   │   │   ├── value-object.ts
│   │   │   ├── domain-event.ts
│   │   │   └── result.ts
│   │   ├── application
│   │   │   ├── use-case.ts
│   │   │   └── event-bus.ts
│   │   ├── infrastructure
│   │   │   ├── database
│   │   │   ├── redis
│   │   │   ├── websocket
│   │   │   ├── logger
│   │   │   └── config
│   │   └── presentation
│   │       ├── errors
│   │       └── middlewares
│   │
│   └── realtime
│       ├── websocket-server.ts
│       ├── connection-registry.ts
│       ├── channels
│       ├── events
│       └── serializers
│
├── prisma
│   └── schema.prisma
├── docker-compose.yml
├── package.json
└── tsconfig.json
```

---

## 8. Estrutura de Pastas — Flutter Web

```txt
web
├── lib
│   ├── main.dart
│   ├── app.dart
│   │
│   ├── core
│   │   ├── config
│   │   ├── theme
│   │   ├── router
│   │   ├── network
│   │   ├── realtime
│   │   ├── storage
│   │   ├── errors
│   │   └── utils
│   │
│   ├── features
│   │   ├── auth
│   │   │   ├── domain
│   │   │   ├── application
│   │   │   ├── data
│   │   │   └── presentation
│   │   │
│   │   ├── workspace
│   │   │   ├── domain
│   │   │   ├── application
│   │   │   ├── data
│   │   │   └── presentation
│   │   │       ├── pages
│   │   │       ├── widgets
│   │   │       └── game
│   │   │           ├── office_canvas.dart
│   │   │           ├── map_renderer.dart
│   │   │           ├── tile_renderer.dart
│   │   │           ├── avatar_renderer.dart
│   │   │           ├── interaction_renderer.dart
│   │   │           └── animation_controller.dart
│   │   │
│   │   ├── avatar
│   │   ├── chat
│   │   ├── meeting
│   │   ├── presence
│   │   ├── interaction
│   │   ├── notification
│   │   └── admin
│   │
│   ├── shared
│   │   ├── widgets
│   │   ├── design_system
│   │   ├── pixel_assets
│   │   └── extensions
│   │
│   └── generated
│
├── assets
│   ├── sprites
│   │   ├── characters
│   │   ├── customization
│   │   ├── gestures
│   │   ├── bubbles
│   │   └── reactions
│   ├── tilesets
│   ├── furniture
│   ├── maps
│   └── sounds
│
├── pubspec.yaml
└── test
```

---

## 9. Modelo de Dados Inicial

## 9.1 Tabelas principais

### users

```txt
id
email
password_hash
display_name
avatar_profile_id
created_at
updated_at
deleted_at
```

### organizations

```txt
id
name
slug
owner_user_id
created_at
updated_at
```

### memberships

```txt
id
organization_id
user_id
role
status
joined_at
created_at
updated_at
```

### workspaces

```txt
id
organization_id
name
slug
status
created_at
updated_at
```

### floors

```txt
id
workspace_id
name
level
map_id
created_at
updated_at
```

### maps

```txt
id
workspace_id
floor_id
name
width
height
tile_size
version
status
json_data
created_at
updated_at
```

### rooms

```txt
id
workspace_id
floor_id
name
type
x
y
width
height
capacity
access_policy
status
created_at
updated_at
```

### desks

```txt
id
workspace_id
floor_id
owner_user_id
name
x
y
width
height
status
created_at
updated_at
```

### avatar_profiles

```txt
id
user_id
skin_tone
hair_style
hair_color
face_style
eye_style
top_clothing
bottom_clothing
shoes
accessories_json
created_at
updated_at
```

### presence_sessions

```txt
id
user_id
workspace_id
floor_id
connection_id
status
x
y
direction
movement_state
last_seen_at
created_at
updated_at
```

### conversations

```txt
id
organization_id
workspace_id
channel_type
room_id
desk_id
created_at
updated_at
```

### messages

```txt
id
conversation_id
sender_user_id
content
type
status
created_at
updated_at
```

### desk_notes

```txt
id
desk_id
from_user_id
to_user_id
content
status
created_at
read_at
```

### interactions

```txt
id
workspace_id
floor_id
from_user_id
to_user_id
target_type
target_id
type
status
payload_json
expires_at
created_at
updated_at
```

### notifications

```txt
id
user_id
type
title
body
payload_json
status
created_at
read_at
```

---

## 10. Eventos Realtime

## 10.1 Client -> Server

### workspace:join

```json
{
  "workspaceId": "uuid",
  "floorId": "uuid"
}
```

### workspace:leave

```json
{
  "workspaceId": "uuid"
}
```

### avatar:move

```json
{
  "x": 120,
  "y": 240,
  "direction": "right",
  "movementState": "walkingRight",
  "timestamp": 1710000000000
}
```

### avatar:stop

```json
{
  "x": 120,
  "y": 240,
  "direction": "right",
  "movementState": "idleRight"
}
```

### presence:status.change

```json
{
  "status": "focus"
}
```

### interaction:send

```json
{
  "type": "wave",
  "targetType": "user",
  "targetId": "uuid"
}
```

### desk:knock

```json
{
  "deskId": "uuid"
}
```

### desk:message.leave

```json
{
  "deskId": "uuid",
  "content": "Passei aqui para falar sobre o projeto."
}
```

### chat:message.send

```json
{
  "channelType": "room",
  "roomId": "uuid",
  "content": "Pessoal, vamos começar?"
}
```

### chat:typing.start

```json
{
  "channelType": "room",
  "roomId": "uuid"
}
```

### chat:typing.stop

```json
{
  "channelType": "room",
  "roomId": "uuid"
}
```

### room:enter

```json
{
  "roomId": "uuid"
}
```

### room:leave

```json
{
  "roomId": "uuid"
}
```

### call:invite

```json
{
  "targetUserId": "uuid",
  "source": "desk",
  "deskId": "uuid"
}
```

---

## 10.2 Server -> Client

### workspace:user.joined

```json
{
  "userId": "uuid",
  "displayName": "Luiz",
  "avatar": {},
  "x": 100,
  "y": 200,
  "status": "available"
}
```

### workspace:user.left

```json
{
  "userId": "uuid"
}
```

### avatar:moved

```json
{
  "userId": "uuid",
  "x": 150,
  "y": 220,
  "direction": "down",
  "movementState": "walkingDown"
}
```

### proximity:user.detected

```json
{
  "nearbyUserId": "uuid",
  "availableActions": ["wave", "call", "chat", "coffee", "shout"]
}
```

### proximity:desk.detected

```json
{
  "deskId": "uuid",
  "ownerUserId": "uuid",
  "availableActions": ["knock", "call", "leaveMessage", "wave"]
}
```

### interaction:received

```json
{
  "interactionId": "uuid",
  "fromUserId": "uuid",
  "type": "wave",
  "payload": {}
}
```

### bubble:show

```json
{
  "targetType": "user",
  "targetId": "uuid",
  "bubbleType": "typing",
  "durationMs": 3000
}
```

### bubble:hide

```json
{
  "targetType": "user",
  "targetId": "uuid",
  "bubbleType": "typing"
}
```

### notification:created

```json
{
  "id": "uuid",
  "type": "deskMessageReceived",
  "title": "Novo recado na sua mesa",
  "body": "Luiz deixou um recado para você."
}
```

---

## 11. Funcionalidades Granulares

## 11.1 Autenticação

### RF-AUTH-001 — Criar conta

Usuário pode criar conta informando:

- Nome.
- Email.
- Senha.

Critérios:

- Email deve ser único.
- Senha deve ser criptografada.
- Criar avatar padrão automaticamente.

### RF-AUTH-002 — Login

Usuário pode entrar com email e senha.

Critérios:

- Retornar access token.
- Retornar organizações do usuário.
- Retornar perfil de avatar.

### RF-AUTH-003 — Logout

Usuário pode sair.

Critérios:

- Encerrar sessão local.
- Encerrar presença WebSocket.
- Emitir evento UserLeftWorkspace se estiver online.

---

## 11.2 Organização

### RF-ORG-001 — Criar organização

Usuário pode criar uma organização.

### RF-ORG-002 — Convidar membro

Admin pode enviar convite por link ou email.

### RF-ORG-003 — Aceitar convite

Usuário pode entrar em organização via token.

### RF-ORG-004 — Gerenciar papéis

Papéis iniciais:

- Owner
- Admin
- Member
- Guest

---

## 11.3 Escritório e Mapa

### RF-WKS-001 — Criar escritório

Admin pode criar um escritório para a organização.

### RF-WKS-002 — Carregar mapa

Sistema carrega:

- Tamanho do mapa.
- Tiles.
- Paredes.
- Objetos.
- Mesas.
- Salas.
- Zonas interativas.

### RF-WKS-003 — Renderizar mapa

Flutter deve renderizar o mapa em camadas:

1. Piso.
2. Tapetes.
3. Paredes.
4. Móveis inferiores.
5. Avatares.
6. Móveis superiores.
7. Balões.
8. UI de interação.

### RF-WKS-004 — Colisão

Avatar não pode atravessar:

- Parede.
- Mesa.
- Armário.
- Planta bloqueante.
- Porta fechada.

### RF-WKS-005 — Zonas interativas

Ao entrar em uma zona:

- Exibir ação disponível.
- Permitir pressionar tecla/clicar.

Exemplos:

- Entrar na sala.
- Sentar na mesa.
- Usar elevador.
- Abrir painel.

---

## 11.4 Avatar e Movimento

### RF-AVA-001 — Criar avatar padrão

Todo usuário recebe avatar padrão.

### RF-AVA-002 — Personalizar avatar

Usuário pode alterar:

- Cor da pele.
- Cabelo.
- Cor do cabelo.
- Rosto.
- Óculos.
- Barba.
- Roupa superior.
- Roupa inferior.
- Sapato.
- Acessórios.

### RF-AVA-003 — Movimento por teclado

Suportar:

- W/A/S/D.
- Setas.

### RF-AVA-004 — Movimento por clique

Usuário pode clicar em ponto do mapa e avatar se mover até lá.

Pode ficar para fase 2 caso complique pathfinding.

### RF-AVA-005 — Animação idle

Quando parado, mostrar sprite idle conforme direção.

### RF-AVA-006 — Animação andando

Quando em movimento, alternar frames de caminhada.

### RF-AVA-007 — Sincronização de movimento

Movimento local deve ser enviado por WebSocket.

O cliente deve interpolar movimento dos outros usuários para evitar travamento visual.

---

## 11.5 Presença

### RF-PRE-001 — Entrar no escritório

Ao abrir o escritório:

- Criar sessão de presença.
- Entrar no canal realtime do escritório.
- Exibir usuário para os demais.

### RF-PRE-002 — Sair do escritório

Ao fechar aba ou sair:

- Remover sessão.
- Emitir evento para outros clientes.

### RF-PRE-003 — Status manual

Usuário pode mudar status:

- Disponível.
- Ocupado.
- Ausente.
- Foco.
- Em reunião.

### RF-PRE-004 — Status automático

Sistema pode mudar status automaticamente:

- Parado por X minutos: Ausente.
- Entrou na sala de reunião: Em reunião.
- Saiu da sala: Disponível ou status anterior.

### RF-PRE-005 — Indicador visual

Cada avatar deve mostrar indicador:

- Verde: disponível.
- Amarelo: ausente.
- Vermelho: ocupado.
- Azul: em reunião.
- Roxo: foco.

---

## 11.6 Mesa do Usuário

### RF-DESK-001 — Mesa com dono

Cada mesa pode ter um dono.

### RF-DESK-002 — Visitar mesa

Usuário pode caminhar até a mesa de outro usuário.

Ao aproximar:

- Aparece painel de ações.
- Aparece nome do dono.
- Aparece status do dono.

### RF-DESK-003 — Chamar dono da mesa

Usuário pode clicar em “Chamar”.

Resultado:

- Dono recebe notificação visual.
- Aparece balão na mesa ou avatar.
- Toca som leve opcional.
- Dono pode aceitar ou ignorar.

### RF-DESK-004 — Bater na mesa

Ação rápida tipo “toc toc”.

Resultado:

- Animação de mão/batida.
- Pequeno balão na mesa.
- Notificação leve.

### RF-DESK-005 — Deixar recado

Se o dono estiver ocupado/offline:

- Visitante pode deixar mensagem.
- Recado fica associado à mesa.
- Dono vê ao voltar.

### RF-DESK-006 — Ver recados da mesa

Dono da mesa pode abrir painel e ver recados recebidos.

### RF-DESK-007 — Mesa ocupada

Se usuário estiver sentado ou ativo na mesa, mostrar estado visual.

---

## 11.7 Salas de Reunião

### RF-ROOM-001 — Entrar na sala

Usuário pode entrar andando até a porta ou zona da sala.

### RF-ROOM-002 — Sair da sala

Usuário pode sair andando ou clicando em sair.

### RF-ROOM-003 — Lista de participantes

Ao entrar, mostrar quem está na sala.

### RF-ROOM-004 — Chat da sala

Mensagens enviadas dentro da sala aparecem no canal da sala.

### RF-ROOM-005 — Estado da sala

Sala pode estar:

- Vazia.
- Com pessoas.
- Em reunião.
- Bloqueada.

### RF-ROOM-006 — Convite para sala

Usuário pode chamar outro usuário para entrar na sala.

### RF-ROOM-007 — Começar reunião

Usuário pode iniciar reunião na sala.

Fase 1:

- Abrir link externo.

Fase 2:

- Iniciar chamada nativa.

---

## 11.8 Chat e Mensagens

### RF-CHAT-001 — Chat global

Canal geral do escritório.

### RF-CHAT-002 — Chat por sala

Cada sala tem canal próprio.

### RF-CHAT-003 — Chat privado

Dois usuários podem conversar em privado.

### RF-CHAT-004 — Chat por proximidade

Opcional: mensagens visíveis para quem está próximo.

### RF-CHAT-005 — Indicador digitando

Quando usuário digita:

- Enviar evento typing.start.
- Mostrar balão com três pontinhos acima do avatar.
- Parar após timeout ou typing.stop.

### RF-CHAT-006 — Balão de mensagem rápida

Mensagens curtas podem aparecer como balão acima do avatar por alguns segundos.

### RF-CHAT-007 — Histórico

Mensagens persistentes ficam no banco.

Indicadores efêmeros não ficam.

---

## 11.9 Gestos e Reações

### RF-GEST-001 — Acenar

Usuário pode acenar para outro.

### RF-GEST-002 — Levantar mão

Usado para pedir atenção em sala ou perto de mesa.

### RF-GEST-003 — Apontar

Gestual visual.

### RF-GEST-004 — Chamar para perto

Ação “vem aqui”.

### RF-GEST-005 — Gritar

Ação de megafone, visível em raio maior.

### RF-GEST-006 — Café

Enviar convite para café/conversa rápida.

### RF-GEST-007 — Ajuda

Pedir ajuda no ambiente.

### RF-GEST-008 — Reações sociais

- Gostei.
- Ideia.
- Alerta.
- Celebração.
- Sono.
- Localização.
- Check.

### RF-GEST-009 — Duração da animação

Cada gesto deve ter duração padrão:

- Wave: 2s.
- Shout: 3s.
- Coffee invite: até aceitar/expirar.
- Typing: enquanto digitando.
- Alert: 5s.

---

## 11.10 Balões Animados

### RF-BUB-001 — Balão de digitação

Mostrar `...` animado.

### RF-BUB-002 — Balão de fala

Mostrar ícone de fala quando usuário está em chamada ou falando.

### RF-BUB-003 — Balão de chamada

Mostrar telefone/pessoa chamando.

### RF-BUB-004 — Balão de grito

Mostrar megafone.

### RF-BUB-005 — Balão de café

Mostrar xícara ou convite.

### RF-BUB-006 — Balão de ajuda

Mostrar ícone de ajuda.

### RF-BUB-007 — Fila de balões

Se várias ações ocorrerem:

- Priorizar chamada e alerta.
- Depois ajuda.
- Depois reações.
- Depois typing.

---

## 11.11 Chamadas

### RF-CALL-001 — Chamar usuário próximo

Usuário perto de outro pode chamar para conversa.

### RF-CALL-002 — Chamar dono da mesa

Usuário pode chamar a partir da mesa.

### RF-CALL-003 — Aceitar chamada

Destinatário aceita e abre canal.

### RF-CALL-004 — Recusar chamada

Destinatário recusa.

### RF-CALL-005 — Expirar chamada

Convite expira após X segundos.

### RF-CALL-006 — Chamada externa inicial

No MVP, aceitar chamada pode abrir link externo ou uma sala interna simples de texto/áudio futuro.

---

## 11.12 Administração

### RF-ADM-001 — Criar sala

Admin pode criar sala com nome, tipo e posição.

### RF-ADM-002 — Criar mesa

Admin pode criar mesa e associar usuário.

### RF-ADM-003 — Editar mapa por JSON

No MVP inicial, mapa pode ser editado via JSON versionado.

### RF-ADM-004 — Publicar mapa

Admin publica uma versão do mapa.

### RF-ADM-005 — Gerenciar membros

Admin vê membros, status e mesas.

---

## 12. Regras de Negócio Importantes

### RN-001 — Presença depende da conexão

Se WebSocket cair, usuário deve ser marcado como desconectado após timeout.

### RN-002 — Movimento precisa ser validado

Backend deve validar posição para evitar usuário atravessando parede por manipulação do client.

### RN-003 — Interação por proximidade

Algumas ações só podem ocorrer se usuário estiver próximo:

- Chamar na mesa.
- Bater na mesa.
- Acenar local.
- Conversa por proximidade.

### RN-004 — Grito tem raio maior

Ação de grito/megafone alcança usuários em raio maior no mesmo andar.

### RN-005 — Recado é persistente

Recado na mesa fica salvo até ser lido/deletado.

### RN-006 — Digitação é efêmera

Indicador de digitação não deve ir para banco.

### RN-007 — Sala altera contexto

Ao entrar em sala:

- Usuário entra no canal realtime da sala.
- Chat muda para sala.
- Participantes são notificados.

### RN-008 — Mesa pertence a workspace/floor

Mesa não pode existir sem floor.

### RN-009 — Avatar sempre tem aparência válida

Se asset customizado falhar, usar fallback padrão.

### RN-010 — Interações expiram

Convites e chamadas não podem ficar pendentes para sempre.

---

## 13. APIs REST Iniciais

## 13.1 Auth

```txt
POST /auth/register
POST /auth/login
POST /auth/logout
GET  /auth/me
```

## 13.2 Organizations

```txt
POST /organizations
GET  /organizations
GET  /organizations/:id
POST /organizations/:id/invitations
POST /invitations/:token/accept
GET  /organizations/:id/members
PATCH /organizations/:id/members/:memberId/role
```

## 13.3 Workspace

```txt
POST /organizations/:organizationId/workspaces
GET  /organizations/:organizationId/workspaces
GET  /workspaces/:workspaceId
GET  /workspaces/:workspaceId/map
GET  /workspaces/:workspaceId/floors/:floorId
```

## 13.4 Rooms

```txt
POST /workspaces/:workspaceId/rooms
GET  /workspaces/:workspaceId/rooms
GET  /rooms/:roomId
PATCH /rooms/:roomId
DELETE /rooms/:roomId
```

## 13.5 Desks

```txt
POST /workspaces/:workspaceId/desks
GET  /workspaces/:workspaceId/desks
GET  /desks/:deskId
PATCH /desks/:deskId/assign
POST /desks/:deskId/messages
GET  /desks/:deskId/messages
```

## 13.6 Avatar

```txt
GET   /avatar/me
PATCH /avatar/me
GET   /avatar/cosmetics
POST  /avatar/preview
```

## 13.7 Chat

```txt
GET  /conversations/:conversationId/messages
POST /conversations/:conversationId/messages
GET  /rooms/:roomId/messages
GET  /private/:userId/messages
```

## 13.8 Notifications

```txt
GET   /notifications
PATCH /notifications/:id/read
PATCH /notifications/read-all
```

---

## 14. Design do Mapa

## 14.1 Camadas do mapa

```txt
Layer 0 — Base floor
Layer 1 — Carpet/decorative floor
Layer 2 — Walls/windows/doors
Layer 3 — Furniture bottom
Layer 4 — Interactive objects
Layer 5 — Avatars
Layer 6 — Furniture top/overlays
Layer 7 — Bubbles/reactions
Layer 8 — UI hints
```

## 14.2 Exemplo de JSON de mapa

```json
{
  "id": "map-001",
  "width": 80,
  "height": 50,
  "tileSize": 32,
  "layers": [
    {
      "name": "floor",
      "tiles": []
    },
    {
      "name": "walls",
      "tiles": []
    },
    {
      "name": "objects",
      "objects": []
    }
  ],
  "collision": [
    { "x": 0, "y": 0, "w": 80, "h": 1 }
  ],
  "interactiveZones": [
    {
      "id": "zone-room-alpha",
      "type": "enterRoom",
      "x": 10,
      "y": 8,
      "w": 3,
      "h": 2,
      "targetId": "room-alpha"
    }
  ]
}
```

---

## 15. UX Principal

## 15.1 Tela de entrada

Fluxo:

1. Usuário faz login.
2. Escolhe organização.
3. Escolhe escritório.
4. Entra no mapa.

## 15.2 Escritório

Elementos:

- Canvas/mapa central.
- Avatar do usuário.
- Avatares online.
- Mini toolbar inferior.
- Chat lateral recolhível.
- Lista de usuários online.
- Notificações.
- Status do usuário.

## 15.3 Ao aproximar da mesa

Mostrar card flutuante:

```txt
Mesa de Ana
Status: Disponível

[Chamar]
[Acenar]
[Deixar recado]
[Café?]
```

## 15.4 Ao aproximar de sala

Mostrar:

```txt
Sala Produto
3 pessoas dentro

[Entrar]
[Ver participantes]
```

## 15.5 Durante digitação

Acima do avatar:

```txt
(...)
```

Com animação alternando pontos.

## 15.6 Durante chamada recebida

Notificação:

```txt
Luiz está chamando você na sua mesa.

[Aceitar]
[Recusar]
[Responder com mensagem]
```

---

## 16. Backlog por Épicos

## EPIC 1 — Fundação técnica

- Configurar monorepo.
- Configurar backend Fastify.
- Configurar web Flutter Web.
- Configurar Docker Compose.
- Configurar PostgreSQL.
- Configurar Redis.
- Configurar autenticação JWT.
- Configurar WebSocket.
- Criar padrão DDD base.

## EPIC 2 — Identidade e organização

- Cadastro.
- Login.
- Organização.
- Membros.
- Convites.
- Papéis.

## EPIC 3 — Workspace e mapa

- Criar workspace.
- Criar floor.
- Criar mapa JSON.
- Renderizar mapa no Flutter.
- Carregar tiles.
- Colisões.
- Objetos interativos.

## EPIC 4 — Avatar e presença

- Criar avatar padrão.
- Movimento local.
- Animação idle/walk.
- Sincronizar movimento.
- Mostrar outros usuários.
- Status online.
- Timeout de desconexão.

## EPIC 5 — Mesas

- Criar mesa.
- Associar mesa a usuário.
- Detectar proximidade.
- Mostrar card da mesa.
- Chamar dono.
- Bater na mesa.
- Deixar recado.
- Ler recados.

## EPIC 6 — Salas

- Criar sala.
- Detectar entrada.
- Entrar/sair.
- Mostrar participantes.
- Canal de sala.
- Status em reunião.
- Convite para sala.

## EPIC 7 — Chat

- Chat global.
- Chat de sala.
- Chat privado.
- Recados.
- Indicador digitando.
- Balão de três pontinhos.

## EPIC 8 — Interações sociais

- Acenar.
- Chamar.
- Gritar.
- Café.
- Ajuda.
- Levantar mão.
- Reações.
- Balões animados.
- Toolbar de ações.

## EPIC 9 — Customização de avatar

- Tela de avatar.
- Escolher pele.
- Cabelo.
- Cor cabelo.
- Roupas.
- Acessórios.
- Preview.
- Persistência.

## EPIC 10 — Admin

- Criar sala pelo admin.
- Criar mesa pelo admin.
- Atribuir mesa.
- Ver usuários online.
- Configurar mapa inicial.

---

## 17. Critérios de Aceite do MVP

O MVP é considerado entregue quando:

1. Dois usuários conseguem entrar no mesmo escritório.
2. Ambos conseguem ver os avatares um do outro.
3. Movimento de um aparece no outro em tempo real.
4. Usuário consegue andar até a mesa de outro.
5. Ao chegar na mesa, aparecem ações contextuais.
6. Usuário consegue chamar o dono da mesa.
7. Dono recebe notificação em tempo real.
8. Usuário consegue deixar recado na mesa.
9. Dono consegue ler recado depois.
10. Usuário consegue entrar em uma sala de reunião.
11. Outros veem que ele entrou.
12. Status muda para em reunião.
13. Chat da sala funciona.
14. Indicador digitando mostra balão animado de três pontinhos.
15. Pelo menos 5 gestos/reações funcionam visualmente.
16. Avatar tem customização básica.
17. Admin consegue atribuir mesa a usuário.

---

## 18. Roadmap Técnico

## Fase 0 — Preparação

- Definir identidade visual.
- Cortar assets pixel art.
- Definir tamanho de tile: 32x32 ou 48x48.
- Definir tamanho base do avatar.
- Definir sprites idle/walk.
- Definir JSON inicial do mapa.

## Fase 1 — Base do produto

- Backend Fastify.
- Front Flutter Web.
- Auth.
- Workspace.
- Mapa estático.

## Fase 2 — Realtime

- WebSocket.
- Presença.
- Movimento.
- Outros usuários.

## Fase 3 — Interação com mesa

- Proximidade.
- Card de ações.
- Chamar.
- Recado.
- Notificação.

## Fase 4 — Salas

- Entrar/sair.
- Participantes.
- Chat.
- Status.

## Fase 5 — Social UX

- Gestos.
- Reações.
- Balões.
- Mini toolbar.
- Animações.

## Fase 6 — Customização

- Avatar builder.
- Partes modulares.
- Preview.

## Fase 7 — Chamada real

- LiveKit ou WebRTC.
- Áudio/vídeo.
- Sala ativa.

## Fase 8 — IA futura

- Agente da sala.
- Resumo de reunião.
- Memória da mesa.
- Busca de contexto.

---

## 19. Decisões Arquiteturais Iniciais

## ADR-001 — Usar Flutter Web no web

### Contexto

O produto precisa ser visual, animado e futuramente pode virar app mobile.

### Decisão

Usar Flutter Web para o web.

### Consequências

Prós:

- Mesmo ecossistema para web/mobile futuro.
- Bom controle visual.
- Componentização forte.
- Boa experiência para canvas/game UI.

Contras:

- SEO irrelevante para app interno.
- Bundle pode ser maior.
- Alguns detalhes de web nativa exigem cuidado.

## ADR-002 — Usar Fastify no backend

### Contexto

Backend precisa ser rápido, modular e em Node.js.

### Decisão

Usar Fastify com TypeScript.

### Consequências

Prós:

- Performance boa.
- Plugin architecture.
- Simples para APIs REST.
- Integra bem com WebSocket.

Contras:

- DDD precisa ser organizado manualmente.

## ADR-003 — Usar WebSocket para tempo real

### Contexto

Movimento, presença e interações precisam ser instantâneos.

### Decisão

Usar WebSocket/Socket.IO no MVP.

### Consequências

Prós:

- Simples para MVP.
- Bom para presença e movimento.

Contras:

- Escala exigirá Redis Pub/Sub e otimização.

## ADR-004 — Usar PostgreSQL como banco principal

### Contexto

Dados relacionais: usuários, organizações, salas, mesas, mensagens.

### Decisão

Usar PostgreSQL.

## ADR-005 — Usar Redis para presença efêmera

### Contexto

Presença e sessões realtime são dados efêmeros.

### Decisão

Usar Redis.

---

## 20. Pontos Críticos de Implementação

### 20.1 Performance do movimento

Não enviar evento a cada pixel se ficar pesado.

Estratégia:

- Client envia posição em intervalos curtos.
- Backend valida e propaga.
- Client interpola.
- Limitar frequência por usuário.

### 20.2 Colisão

No MVP:

- Colisão pode ser validada no client para UX.
- Backend valida posições críticas para segurança.

### 20.3 Escala realtime

Separar canais:

- workspace:{id}
- floor:{id}
- room:{id}
- user:{id}

### 20.4 Estado efêmero vs persistente

Persistente:

- Usuário.
- Organização.
- Workspace.
- Sala.
- Mesa.
- Mensagem.
- Recado.
- Avatar.

Efêmero:

- Movimento.
- Digitação.
- Balão.
- Gesto temporário.
- Presença instantânea.

### 20.5 Assets

No MVP:

- Assets podem ficar em `assets/` no Flutter.

Depois:

- Versionar asset packs no backend.
- CDN/storage.

---

## 21. Primeira Sprint Recomendada

## Sprint 1 — Base técnica e primeiro mapa

### Backend

- Criar projeto Fastify TypeScript.
- Criar módulos shared.
- Criar auth simples.
- Criar usuário.
- Criar organização.
- Criar workspace.
- Criar endpoint de mapa mockado.
- Criar WebSocket básico.

### Web

- Criar Flutter Web.
- Criar tema base.
- Criar login.
- Criar tela de seleção de workspace.
- Criar renderização de mapa mockado.
- Criar avatar local andando.

### Resultado esperado

Um usuário logado consegue entrar em um mapa e andar com avatar local.

---

## 22. Segunda Sprint Recomendada

## Sprint 2 — Presença realtime

### Backend

- WebSocket com autenticação JWT.
- Evento workspace:join.
- Evento avatar:move.
- Evento avatar:moved.
- Registry de conexões.
- Estado no Redis.

### Web

- Conectar WebSocket.
- Enviar movimento.
- Receber outros usuários.
- Renderizar avatares remotos.
- Interpolar movimento.

### Resultado esperado

Dois usuários entram no mesmo mapa e veem um ao outro andando.

---

## 23. Terceira Sprint Recomendada

## Sprint 3 — Mesa e chamar colega

### Backend

- Criar desks.
- Associar mesa a usuário.
- Detectar proximidade no client/backend.
- Evento desk:knock.
- Evento call:invite.
- Notificação realtime.
- Recado na mesa.

### Web

- Renderizar mesas.
- Detectar aproximação.
- Mostrar card de ações.
- Botão chamar.
- Botão deixar recado.
- Balão de chamada.

### Resultado esperado

Usuário consegue ir até a mesa de outro, chamar e deixar recado.

---

## 24. Quarta Sprint Recomendada

## Sprint 4 — Salas e chat

### Backend

- Criar rooms.
- Entrar/sair da sala.
- Canal realtime de sala.
- Mensagens de sala.
- Typing indicator.

### Web

- Zonas de entrada.
- UI da sala.
- Chat lateral.
- Balão de três pontinhos.
- Lista de participantes.

### Resultado esperado

Usuários entram na sala e conversam com balão animado de digitação.

---

## 25. Quinta Sprint Recomendada

## Sprint 5 — Gestos, reações e toolbar

### Backend

- Eventos de interação.
- Validação de proximidade.
- Expiração de interações.

### Web

- Mini toolbar.
- Ícones de ações.
- Animação de wave.
- Megafone/grito.
- Café.
- Ajuda.
- Reações.

### Resultado esperado

Produto começa a parecer vivo e social.

---

## 26. Definition of Done

Uma tarefa só está pronta quando:

- Código compila.
- Tipos TypeScript/Dart estão corretos.
- Caso de uso tem teste unitário quando aplicável.
- API validada com schema.
- Evento realtime documentado.
- UI testada manualmente.
- Não quebra fluxo existente.
- Segue DDD e separação de camadas.
- Não mistura regra de negócio dentro de controller/widget.
- Erros são tratados.
- Logs importantes existem.

---

## 27. Guardrails para Desenvolvimento com IA

Usar sempre estas regras ao pedir implementação para agentes de IA:

1. Responder sempre em português.
2. Antes de alterar código, explicar plano de ação.
3. Mexer somente nos arquivos necessários.
4. Não refatorar fora do escopo.
5. Respeitar DDD, SOLID, Clean Code e Hexagonal.
6. Separar domínio, aplicação, infraestrutura e apresentação.
7. Criar ou atualizar testes quando fizer sentido.
8. Não criar dependências desnecessárias.
9. Não remover código existente sem justificar.
10. Atualizar documentação quando criar evento, endpoint ou regra nova.
11. Para UI, seguir pixel perfect e design system.
12. Para realtime, documentar contrato client/server.
13. Para domínio, usar linguagem ubíqua.
14. Para mapa, respeitar camadas e colisão.
15. Para assets, manter nomes padronizados.

---

## 28. Próximos Arquivos Recomendados

Após este PLAN.md, criar:

```txt
/docs
├── PRD.md
├── FSD.md
├── ADR.md
├── UBIQUITOUS_LANGUAGE.md
├── DOMAIN_MODEL.md
├── REALTIME_EVENTS.md
├── API_CONTRACTS.md
├── MAP_SCHEMA.md
├── AVATAR_CUSTOMIZATION.md
├── ASSET_PIPELINE.md
├── WEB_ARCHITECTURE.md
├── BACKEND_ARCHITECTURE.md
└── TEST_STRATEGY.md
```

---

## 29. Resumo Executivo

Este projeto deve ser tratado como um produto de **escritório virtual vivo**, não apenas um chat com mapa.

O coração do sistema é o Core Domain:

- Workspace.
- Presença.
- Movimento.
- Proximidade.
- Mesas.
- Salas.
- Interações sociais.
- Balões animados.

A primeira versão deve focar em:

1. Mapa 2D.
2. Avatar andando.
3. Presença realtime.
4. Mesa do colega.
5. Chamar colega.
6. Deixar recado.
7. Entrar em sala.
8. Chat de sala.
9. Balão de digitação.
10. Gestos e reações.

Com isso, o produto já entrega a sensação principal: **estar em um escritório virtual com outras pessoas**.

