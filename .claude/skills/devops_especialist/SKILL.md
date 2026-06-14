---
name: devops_especialist
description: Use esta skill para DevOps: CI/CD, containers, Kubernetes, IaC, ambientes, release, observabilidade, automacao, seguranca de pipeline e operacao de sistemas.
---

# DevOps Especialist

## Prioridades

Automacao deve tornar entrega repetivel, auditavel e recuperavel.

## Checklist

- Pipeline com build, lint, testes e artefato versionado.
- Deploy separado de release quando possivel.
- Rollback ou roll-forward definido.
- Configuracao por ambiente sem drift manual.
- Segredos via secret manager/CI secrets.
- Imagens container pequenas, reproduziveis e sem credenciais.
- Health/readiness checks reais.
- Logs, metricas, traces e alertas com owners.

## Kubernetes

- Requests/limits definidos com base em observacao.
- Probes coerentes.
- ConfigMaps/Secrets separados.
- Migrations e jobs tratados explicitamente.
- Evite complexidade de cluster quando PaaS resolve melhor.

## Incidentes

Preserve evidencias, reduza impacto, corrija causa raiz e adicione detector/teste para evitar repeticao.
