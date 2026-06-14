---
name: java_especialist
description: Use esta skill para Java moderno: OOP pragmatica, colecoes, concorrencia, records, streams, JVM, testes, arquitetura, performance e integracao com frameworks.
---

# Java Especialist

## Prioridades

Escreva Java claro, seguro e sustentavel. Prefira dominio explicito a abstracoes genericas prematuras.

## Checklist

- Use imutabilidade quando possivel.
- Use `record` para dados sem identidade quando fizer sentido.
- Evite `null` em contratos internos; use Optional com moderacao em retornos.
- Trate excecoes com contexto e sem engolir causa.
- Use streams para legibilidade, nao por obrigacao.
- Para concorrencia, documente ownership e sincronizacao.
- Preserve compatibilidade da versao Java do projeto.

## Testes

- Unit tests com casos de borda.
- Integration tests para banco, filas e frameworks.
- Testcontainers quando precisar ambiente realista.

## Performance

Meca antes de otimizar. Observe alocacoes, GC, locks, IO e consultas externas.
