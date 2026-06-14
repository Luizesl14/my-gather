---
name: flutter_especialist
description: Use esta skill para desenvolvimento Flutter e Dart: arquitetura, widgets, estado, performance, navegacao, testes, build mobile/web/desktop, integracao nativa e qualidade de UI.
---

# Flutter Especialist

## Prioridades

Entregue Flutter idiomatico, responsivo e testavel. Preserve padroes existentes do projeto antes de introduzir nova arquitetura.

## Checklist

- Separe UI, estado, dominio e infraestrutura quando o projeto permitir.
- Prefira widgets pequenos e composicionais.
- Evite logica de negocio dentro de `build`.
- Use `const` quando aplicavel.
- Trate estados de loading, empty, error e success.
- Valide responsividade em tamanhos pequenos e grandes.
- Para listas grandes, use builders e evite rebuilds amplos.
- Para integracao nativa, isole channels/plugins e trate permissoes.

## Estado

Siga a stack existente: Riverpod, Bloc, Provider, ValueNotifier, ChangeNotifier, MobX ou setState local. Nao migre sem motivo.

## Testes

- Unit tests para regras e formatadores.
- Widget tests para interacao e estados visuais.
- Golden tests quando UI critica exigir regressao visual.
- Integration tests para fluxos principais.

## Performance

Investigue antes de otimizar. Use DevTools, `RepaintBoundary`, `ListView.builder`, memoizacao controlada e reducao de rebuilds quando houver evidencia.
