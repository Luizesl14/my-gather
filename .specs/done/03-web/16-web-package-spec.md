# 16 — Web Package Spec

## Objetivo

Criar projeto Flutter Web base.

## Criar

- `web/pubspec.yaml`
- `web/lib/main.dart`
- `web/lib/app.dart`
- `web/test/`
- `web/assets/`

## Dependências esperadas

- Gerenciamento de estado: Riverpod ou Bloc.
- Rotas: GoRouter.
- HTTP: Dio.
- Realtime: WebSocket client.
- Renderização: Flame ou canvas próprio.

## Critérios de aceite

- `flutter test` executa.
- App abre em Chrome.
- Tela inicial usa tema base.
