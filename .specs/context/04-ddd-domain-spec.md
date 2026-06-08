# DDD Domain Spec

## Arquitetura

Backend: Fastify + TypeScript em módulos DDD.

Cada módulo deve separar:

- `domain`: entidades, value objects, agregados, eventos, serviços de domínio e contratos de repositório.
- `application`: use cases, commands, queries, ports e DTOs de entrada/saída.
- `infrastructure`: persistência, Redis, WebSocket, provedores externos e mappers.
- `presentation`: rotas HTTP, schemas Zod, handlers WebSocket e serializers.

Regra: controllers, widgets e renderizadores não contêm regra de negócio.

## Linguagem ubíqua

Termos obrigatórios no código e documentação:

- Organização.
- Escritório.
- Andar.
- Mapa.
- Tile.
- Avatar.
- Mesa.
- Sala.
- Área comum.
- Presença.
- Posição.
- Proximidade.
- Interação.
- Chamada.
- Recado.
- Balão.
- Gesto.
- Reação.
- Sessão.
- Canal.
- Zona Interativa.

## Identity Context

Responsabilidade: identidade, organizações, membros, convites, papéis e permissões.

Entidades:

- `User`
- `Organization`
- `Membership`
- `Role`
- `Invitation`

Value Objects:

- `Email`
- `PasswordHash`
- `DisplayName`
- `OrganizationName`
- `RoleName`
- `InvitationToken`

Agregados:

- `UserAggregate`: cria usuário, atualiza perfil, valida email, ativa/desativa conta.
- `OrganizationAggregate`: cria organização, adiciona/remove membro, altera papel, cria convite.

Eventos:

- `UserRegistered`
- `UserProfileUpdated`
- `OrganizationCreated`
- `MemberJoinedOrganization`
- `MemberRemovedFromOrganization`
- `InvitationCreated`
- `InvitationAccepted`

Use cases:

- `RegisterUserUseCase`
- `LoginUserUseCase`
- `CreateOrganizationUseCase`
- `InviteMemberUseCase`
- `AcceptInvitationUseCase`
- `ChangeMemberRoleUseCase`

## Workspace Context — Core

Responsabilidade: escritório, andares, mapa, salas, mesas e zonas interativas.

Entidades:

- `Workspace`
- `Floor`
- `Room`
- `Desk`
- `Map`
- `MapObject`
- `InteractiveZone`

Value Objects:

- `WorkspaceId`
- `FloorId`
- `RoomId`
- `DeskId`
- `TileCoordinate`
- `MapSize`
- `CollisionArea`
- `ObjectType`
- `RoomType`

Agregados:

- `WorkspaceAggregate`: escritório pertence a organização, possui andares e mapa ativo.
- `FloorAggregate`: contém mapa, salas, mesas, objetos e zonas.
- `RoomAggregate`: nome, tipo, capacidade, área, política de acesso e estado.
- `DeskAggregate`: dono, localização, estado, recados e permissões.

Regras:

- Um escritório pertence a uma organização.
- Um escritório precisa ter pelo menos um mapa ativo para entrada de usuários.
- Mesa deve ocupar posição válida no andar.
- Sala deve ter área válida no mapa.
- Zona interativa deve apontar para ação conhecida.
- Objetos bloqueantes geram colisão.
- Mesa não pode existir sem floor.

Eventos:

- `WorkspaceCreated`
- `FloorCreated`
- `MapPublished`
- `RoomCreated`
- `RoomUpdated`
- `RoomEntered`
- `RoomLeft`
- `DeskAssigned`
- `DeskVisited`
- `DeskMessageLeft`
- `InteractiveZoneTriggered`

## Presence Context — Core

Responsabilidade: sessão realtime, posição, movimento, status e proximidade.

Entidades:

- `Session`
- `AvatarPresence`
- `AvatarPosition`
- `ProximityInteraction`

Value Objects:

- `ConnectionId`
- `Position`
- `Direction`
- `MovementState`
- `PresenceStatus`
- `ProximityRadius`

Estados:

- Presença: `Online`, `Available`, `Away`, `Busy`, `InMeeting`, `Focus`, `Offline`.
- Movimento: `IdleFront`, `IdleBack`, `IdleLeft`, `IdleRight`, `WalkingUp`, `WalkingDown`, `WalkingLeft`, `WalkingRight`.

Agregado:

- `AvatarPresenceAggregate`: usuário, sessão ativa, workspace, floor, posição, direção, status e última atividade.

Regras:

- Avatar só move para posição válida.
- Avatar não atravessa paredes, objetos bloqueantes ou limite do mapa.
- Backend valida movimento para impedir manipulação do client.
- Posição é propagada em tempo real.
- Entrar em sala pode mudar status automaticamente.
- Inatividade muda status para `Away` depois do timeout configurado.
- Queda de WebSocket marca desconectado depois do grace period.

Eventos:

- `UserEnteredWorkspace`
- `UserLeftWorkspace`
- `AvatarMoved`
- `AvatarStopped`
- `PresenceStatusChanged`
- `ProximityDetected`
- `ProximityLost`
- `UserBecameAway`
- `UserReturnedAvailable`

## Interaction Context — Core

Responsabilidade: ações sociais entre usuários, mesas, salas e objetos.

Entidades:

- `Interaction`
- `Gesture`
- `Reaction`
- `InteractionBubble`
- `InteractionRequest`

Value Objects:

- `InteractionType`
- `GestureType`
- `ReactionType`
- `BubbleType`
- `InteractionTarget`
- `InteractionDuration`

Estados:

- `Created`
- `Sent`
- `Received`
- `Accepted`
- `Rejected`
- `Expired`
- `Cancelled`

Tipos:

- Usuário para usuário: `Wave`, `CallUser`, `InviteToMeeting`, `AskForHelp`, `ComeHere`, `FollowMe`, `Shout`, `SendCoffeeInvite`, `SendReaction`.
- Usuário para mesa: `VisitDesk`, `LeaveMessage`, `KnockDesk`, `CallDeskOwner`, `RequestAvailability`.
- Usuário para sala: `EnterRoom`, `LeaveRoom`, `InviteToRoom`, `RaiseHand`, `RequestMeeting`.
- Usuário para ambiente: `OpenDoor`, `UseElevator`, `SitOnChair`, `OpenWhiteboard`, `OpenScreen`, `InteractWithObject`.

Regras:

- Interações podem exigir proximidade ou permitir alcance remoto.
- Toda interação efêmera deve expirar.
- Algumas interações geram notificação.
- Algumas geram balão animado.
- Algumas geram mensagem persistente.
- `Shout` tem raio maior no mesmo andar.

Eventos:

- `InteractionRequested`
- `InteractionDelivered`
- `InteractionAccepted`
- `InteractionRejected`
- `InteractionExpired`
- `GesturePerformed`
- `ReactionSent`
- `BubbleDisplayed`
- `BubbleHidden`
- `DeskKnocked`
- `UserCalledFromDesk`

## Communication Context — Supporting

Responsabilidade: mensagens, conversas, canais, typing e recados.

Entidades:

- `Conversation`
- `Message`
- `Channel`
- `TypingIndicator`
- `DeskNote`

Value Objects:

- `MessageContent`
- `ChannelType`
- `MessageStatus`
- `TypingState`

Canais:

- `GlobalWorkspaceChannel`
- `RoomChannel`
- `PrivateChannel`
- `DeskChannel`
- `ProximityChannel`

Regras:

- Mensagem de sala só aparece para participantes ou usuários com permissão.
- Recado de mesa persiste mesmo com dono offline.
- Typing não é persistido.
- Balão de três pontos é estado efêmero realtime.

Eventos:

- `MessageSent`
- `MessageReceived`
- `MessageRead`
- `UserStartedTyping`
- `UserStoppedTyping`
- `DeskNoteCreated`
- `DeskNoteRead`

## Meeting Context — Supporting

Responsabilidade: salas de reunião, participantes e chamadas.

Entidades:

- `MeetingRoom`
- `MeetingSession`
- `MeetingParticipant`
- `CallInvite`

Value Objects:

- `MeetingStatus`
- `ParticipantRole`
- `CallProvider`
- `ExternalMeetingUrl`

Estados:

- `Idle`
- `Waiting`
- `Active`
- `Locked`
- `Finished`

Regras:

- MVP pode abrir link externo.
- Aceitar chamada pode abrir canal interno simples ou link externo.
- Convite de chamada expira.

Eventos:

- `MeetingStarted`
- `MeetingEnded`
- `ParticipantJoinedMeeting`
- `ParticipantLeftMeeting`
- `CallInviteSent`
- `CallInviteAccepted`
- `CallInviteRejected`

## Avatar Customization Context — Supporting

Responsabilidade: aparência do avatar.

Entidades:

- `AvatarProfile`
- `AvatarOutfit`
- `CosmeticAsset`
- `AnimationSet`

Value Objects:

- `SkinTone`
- `HairStyle`
- `HairColor`
- `FaceStyle`
- `EyeStyle`
- `TopClothing`
- `BottomClothing`
- `Shoes`
- `Accessory`
- `SpriteLayer`

Regras:

- Todo avatar tem corpo base.
- Toda combinação deve produzir visual válido.
- Assets possuem versão.
- Avatar deve ter sprites idle e walking.
- Se asset customizado falhar, usar fallback padrão.

## Notification Context — Supporting

Responsabilidade: notificações visuais, sonoras e persistentes.

Tipos:

- `UserCalled`
- `DeskMessageReceived`
- `MeetingInviteReceived`
- `MentionReceived`
- `HelpRequested`
- `CoffeeInviteReceived`
- `SystemAlert`

Eventos:

- `NotificationCreated`
- `NotificationDelivered`
- `NotificationRead`
- `NotificationDismissed`

## Asset Context — Supporting

Responsabilidade: sprites, tilesets, objetos, móveis, animações e versões de assets.

Entidades:

- `AssetPack`
- `SpriteAsset`
- `TilesetAsset`
- `AnimationAsset`
- `ObjectAsset`

Value Objects:

- `AssetType`
- `AssetPath`
- `SpriteFrame`
- `AnimationFrame`
- `CollisionMask`

Eventos:

- `AssetPackCreated`
- `AssetUploaded`
- `AssetVersionPublished`
- `AssetDeprecated`

## Generic Contexts

Billing, File Storage, Email Delivery, Audit Log e Observability são domínios genéricos. Podem usar soluções prontas, desde que as portas fiquem isoladas na camada de aplicação.
