---
name: domain_drive_desing
description: Use esta skill para modelagem Domain-Driven Design, mesmo com o nome escrito como domain_drive_desing. Acione para subdominios core/support/generic, bounded contexts, context mapping, agregados, entidades, value objects, domain events, factories, repositories, application services e arquitetura orientada ao dominio.
---

# Domain Drive Desing

## Missao

Modelar software a partir do dominio, separando linguagem, regras de negocio e limites de contexto antes de escolher estrutura tecnica.

## Fluxo DDD

1. Extraia a linguagem ubiqua: termos do negocio, acoes, politicas, excecoes e eventos.
2. Classifique subdominios:
   - core: diferencial competitivo e alta complexidade;
   - supporting: necessario ao negocio, mas nao diferencial principal;
   - generic: commodity, pode usar solucao pronta.
3. Defina bounded contexts por linguagem, modelo e ownership.
4. Crie context map: upstream/downstream, partnership, customer-supplier, conformist, anticorruption layer, shared kernel, open-host service.
5. Modele agregados somente onde ha invariantes transacionais.
6. Use domain events para fatos relevantes ja ocorridos.
7. Use factories quando a criacao tiver invariantes ou montagem complexa.
8. Use repositories para persistencia de agregados, nao para qualquer tabela.

## Heuristicas

- Agregado pequeno e consistente vence agregado gigante.
- Transacao forte fica dentro de um agregado.
- Consistencia eventual entre agregados deve ser explicita por evento/process manager.
- Entidade tem identidade; value object tem igualdade por valor.
- Service de dominio so existe quando a regra nao pertence naturalmente a uma entidade/value object.
- Application service coordena caso de uso; nao deve conter regra de negocio profunda.

## Entregaveis

Quando solicitado, produza:

- mapa de subdominios;
- lista de bounded contexts e responsabilidades;
- context map textual;
- agregados com invariantes;
- eventos de dominio;
- comandos/casos de uso;
- riscos de acoplamento e decisoes arquiteturais.
