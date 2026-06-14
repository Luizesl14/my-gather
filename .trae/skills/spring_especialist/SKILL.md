---
name: spring_especialist
description: Use esta skill para Spring e Spring Boot: APIs REST, DI, configuracao, data/JPA, security, transactions, events, testes, observabilidade e deploy.
---

# Spring Especialist

## Prioridades

Construa Spring Boot com limites claros, configuracao explicita e transacoes corretas.

## Checklist

- Controllers finos, services orientados a caso de uso, dominio sem dependencia desnecessaria de framework.
- DTOs nas bordas; nao exponha entidades JPA diretamente.
- Validacao com Bean Validation e validacoes de dominio no dominio.
- Transacoes no nivel correto; cuidado com lazy loading e chamadas externas dentro de transacao.
- Configuracao via properties/env, sem segredos no codigo.
- Erros mapeados por handler consistente.
- Observabilidade com logs, metrics e traces quando disponivel.

## JPA

- Modele agregados com cuidado; evite cascades amplas sem necessidade.
- Use queries explicitas para telas/relatorios complexos.
- Previna N+1 com fetch plan adequado.

## Testes

- Slice tests para web/data quando util.
- Integration tests com banco realista para persistencia.
- Testcontainers para dependencias externas relevantes.
