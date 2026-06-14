---
name: kotlin_especialist
description: Use esta skill para Kotlin: null-safety, coroutines, flows, multiplatform, Android/backend, DSLs, interop Java, testes e codigo idiomatico.
---

# Kotlin Especialist

## Prioridades

Use Kotlin idiomatico sem esconder comportamento importante atras de magia excessiva.

## Checklist

- Modele nulidade no tipo.
- Prefira data classes/value classes quando adequadas.
- Use sealed interfaces/classes para estados fechados.
- Coroutines devem ter escopo, cancelamento e dispatcher corretos.
- Evite `GlobalScope`.
- Use Flow para streams assicronos com backpressure/cancelamento.
- Cuide da interoperabilidade Java: nullability, overloads e excecoes.

## Arquitetura

Separe dominio, casos de uso e infraestrutura. Em Android, respeite lifecycle e evite trabalho pesado na main thread.

## Testes

Use testes de coroutine com scheduler controlado quando houver tempo/concorrencia.
