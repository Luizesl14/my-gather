# Product Spec — Escritório Virtual Interativo

## Produto

Nome provisório: **Atom Office**.

Produto: escritório virtual 2D navegável, inspirado na experiência social do Gather, com identidade própria em pixel art corporativo. Usuários entram em uma organização, acessam um escritório, controlam avatares, veem presença em tempo real, visitam mesas, entram em salas, conversam por chat e usam ações sociais visuais.

## Problema

Times remotos e híbridos perdem sinais espontâneos do escritório físico:

- Disponibilidade dos colegas fica invisível.
- Conversas rápidas viram reuniões formais.
- Não existe sensação de presença compartilhada.
- Comunicação fica fragmentada entre chat, calendário e chamadas.
- Novos membros não percebem cultura, rotina e pessoas do ambiente.

## Solução

Criar um escritório vivo com:

- Mapa 2D navegável.
- Avatares personalizáveis.
- Presença e movimento em tempo real.
- Mesas individuais.
- Salas de reunião e áreas comuns.
- Chat global, por sala, privado, por mesa e futuro canal por proximidade.
- Chamar colega, bater na mesa, deixar recado e convidar para café.
- Gestos, reações e balões animados.
- Admin para configurar salas, mesas, membros e mapa inicial.

## MVP

O MVP deve entregar a sensação principal: duas ou mais pessoas estão no mesmo escritório virtual e conseguem interagir visualmente.

### Incluído

- Cadastro, login e logout.
- Organização e associação de membros.
- Escritório com pelo menos um andar.
- Mapa estático em JSON.
- Renderização 2D em camadas.
- Avatar local andando por teclado.
- Outros usuários online renderizados no mapa.
- Movimento sincronizado via WebSocket.
- Status de presença manual e automático.
- Mesa com dono.
- Detecção de proximidade com mesa, usuário e sala.
- Card contextual ao aproximar.
- Chamar colega.
- Bater na mesa.
- Deixar recado persistente.
- Entrar e sair de sala.
- Chat de sala.
- Indicador digitando com balão animado.
- Pelo menos cinco gestos/reacões visuais: acenar, chamar, gritar, café e ajuda.
- Customização básica de avatar.
- Admin atribui mesa a usuário.

### Fora do MVP

- Áudio espacial completo.
- Vídeo nativo completo.
- Editor visual avançado de mapa.
- Marketplace de mapas.
- IA por sala.
- Gravação, transcrição e resumo de reunião.
- Billing completo.
- App mobile nativo.

## Personas

### Membro remoto

Quer saber quem está disponível, chamar alguém rapidamente e sentir presença do time.

### Pessoa em foco

Quer aparecer no escritório, mas sinalizar indisponibilidade e evitar interrupções.

### Gestor/Admin

Quer organizar mesas, salas, permissões e onboarding visual do time.

### Novo membro

Quer entender onde as pessoas ficam, quem participa de cada área e como pedir ajuda.

## Jornadas principais

### Entrar no escritório

1. Usuário faz login.
2. Seleciona organização.
3. Seleciona escritório.
4. Entra no mapa.
5. Avatar aparece na posição inicial ou última posição válida.
6. Outros membros recebem `workspace:user.joined`.

### Chamar colega na mesa

1. Usuário caminha até mesa de colega.
2. Sistema detecta proximidade.
3. Card contextual exibe dono, status e ações.
4. Usuário clica em chamar.
5. Destinatário recebe notificação e balão.
6. Convite pode ser aceito, recusado ou expirar.

### Deixar recado

1. Usuário visita mesa.
2. Escolhe `Deixar recado`.
3. Escreve mensagem.
4. Sistema persiste `DeskNote`.
5. Dono recebe notificação quando online ou ao voltar.

### Entrar em sala

1. Usuário entra na zona interativa da porta.
2. Sistema exibe ação `Entrar`.
3. Usuário confirma.
4. Presença muda para `InMeeting` se a sala for de reunião.
5. Usuário entra no canal realtime da sala.
6. Chat lateral muda para contexto da sala.

## Critérios de aceite do MVP

- Dois usuários conseguem entrar no mesmo escritório.
- Movimento de um usuário aparece no outro em tempo real.
- Avatar não atravessa paredes ou objetos bloqueantes.
- Usuário consegue visitar mesa de outro membro.
- Card contextual aparece apenas dentro do raio configurado.
- Chamada gera notificação realtime, balão visual e estado de expiração.
- Recado de mesa persiste e pode ser lido depois.
- Usuário entra e sai de sala.
- Status muda corretamente ao entrar em sala.
- Chat de sala envia, recebe e lista histórico.
- Indicador de digitação aparece como balão efêmero.
- Gestos e reações aparecem com duração e prioridade corretas.
- Avatar possui aparência válida mesmo quando asset falha.
- Admin consegue associar mesa a membro.
