# Test Strategy Spec

## Objetivo

Garantir que o produto funcione como escritório virtual realtime sem quebrar regras de domínio, contratos de eventos, renderização de mapa e fluxos críticos.

## Pirâmide de testes

### Backend

- Unitários de domínio.
- Unitários de use cases.
- Integração de repositórios.
- Integração REST.
- Integração WebSocket.
- Contratos de eventos.

### Web

- Unitários de domínio/application quando houver.
- Widget/component tests.
- Testes de renderer/canvas com snapshots ou pixel checks quando viável.
- Testes de estado realtime mockado.
- Testes manuais guiados para animações e mapa.

### E2E

- Login.
- Entrar no workspace.
- Dois usuários no mesmo mapa.
- Movimento realtime.
- Proximidade com mesa.
- Chamar colega.
- Deixar recado.
- Entrar em sala.
- Chat de sala.
- Typing bubble.

## Testes obrigatórios por contexto

### Identity

- Email único.
- Senha criptografada.
- Convite válido/expirado.
- Alteração de papel respeita permissão.

### Workspace

- Workspace precisa de organização.
- Floor precisa de workspace.
- Mesa não pode ficar fora do mapa.
- Sala não pode ter área inválida.
- Publicação de mapa rejeita colisões inválidas.

### Presence

- Entrar no escritório cria sessão.
- Sair remove sessão.
- Movimento inválido é rejeitado.
- Status muda para Away por inatividade.
- Entrar em sala muda status conforme regra.
- Queda de conexão marca offline após timeout.

### Interaction

- Ação que exige proximidade falha fora do raio.
- Grito alcança raio maior no mesmo floor.
- Convite expira.
- Chamada aceita muda estado.
- Balão correto é gerado para cada interação.

### Communication

- Mensagem de sala não aparece para usuário sem permissão.
- Recado persiste.
- Typing não persiste.
- Message status atualiza corretamente.

### Meeting

- Entrar na sala adiciona participante.
- Sair remove participante.
- Iniciar reunião muda estado.
- Link externo é validado quando usado.

### Avatar

- Avatar padrão é criado.
- Combinação inválida usa fallback.
- Customização salva IDs válidos.

### Notification

- Notificação é criada para chamada e recado.
- Notificação lida muda status.
- Preferências bloqueiam sons quando configurado.

## Testes visuais e animações

Verificar manualmente e, quando possível, automatizar:

- Light/dark mode aplicados sem perda de contraste.
- Toolbar não cobre avatar em desktop.
- Chat recolhe/expande sem quebrar layout.
- Card contextual não aparece fora do raio.
- Balões respeitam prioridade.
- Typing bubble anima e expira.
- Knock faz shake curto.
- Chamada pulsa e expira.
- Grito mostra megafone/linhas por 3s.
- Reações flutuam e somem sem deslocar layout.
- `prefers-reduced-motion` reduz movimento.

## Contratos

Todo endpoint REST deve ter:

- Schema de entrada.
- Schema de saída.
- Erros previstos.
- Teste de validação.

Todo evento WebSocket deve ter:

- Nome estável.
- Payload documentado.
- Emissor.
- Receptores.
- Persistência ou efemeridade.
- Teste de contrato.

## Definition of Done

Uma tarefa está pronta quando:

- Código compila.
- Tipos TypeScript/Dart estão corretos.
- Use case crítico tem teste unitário.
- API é validada por schema.
- Evento realtime criado ou alterado está documentado.
- UI foi testada manualmente em light e dark.
- Fluxo principal não quebrou.
- DDD e camadas foram respeitados.
- Erros são tratados.
- Logs importantes existem.
- Documentação foi atualizada quando regra, endpoint ou evento mudou.
