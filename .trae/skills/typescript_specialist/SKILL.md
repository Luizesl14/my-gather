---
name: typescript_specialist
description: Use esta skill para TypeScript avancado: tipos, generics, narrowing, APIs type-safe, refactors, configuracao tsconfig, bibliotecas, monorepos e eliminacao de any.
---

# TypeScript Specialist

## Prioridades

Use o sistema de tipos para expressar contratos reais sem criar complexidade ornamental.

## Regras

- Prefira tipos derivados de fonte unica quando possivel.
- Evite `any`; se inevitavel, isole e explique.
- Use `unknown` nas bordas e valide antes de usar.
- Modele estados impossiveis com unions discriminadas.
- Use generics quando preservam relacao entre entrada e saida.
- Nao use casts para silenciar problema que deveria ser modelado.
- Preserve inferencia publica de APIs.

## Checklist

- `strict` e opcoes do `tsconfig` consideradas.
- Erros de runtime tratados por validacao, nao so por tipos.
- Tipos exportados sao estaveis e legiveis.
- Refactors mantem compatibilidade quando a API for publica.

## Testes

Use testes runtime para comportamento e, quando o projeto permitir, testes de tipo com `tsd`, `expect-type` ou validacoes equivalentes.
