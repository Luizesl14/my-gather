---
name: cloude_specialist
description: Use esta skill para cloud/cloud engineering, mesmo quando escrito como cloude_specialist: AWS, GCP, Azure, arquitetura cloud, redes, IAM, custos, seguranca, escalabilidade, resiliencia e servicos gerenciados.
---

# Cloude Specialist

## Prioridades

Arquitetura cloud deve ser segura, observavel, resiliente e proporcional ao custo/risco do produto.

## Checklist

- Defina requisitos: disponibilidade, latencia, dados, compliance, custo e escala.
- Escolha servicos gerenciados quando reduzem operacao sem prender o dominio.
- Aplique menor privilegio em IAM.
- Separe ambientes e contas/projetos quando necessario.
- Configure logs, metricas, traces e alertas.
- Planeje backup, restore e DR.
- Modele custo antes de superdimensionar.
- Automatize infraestrutura com IaC quando o ambiente precisa ser reproduzivel.

## Seguranca

- Sem segredo em codigo, imagem ou repo.
- Criptografia em transito e repouso quando aplicavel.
- Rotacao e escopo de credenciais.
- Regras de rede explicitas.

## Resiliencia

Use timeouts, retries com backoff, circuit breakers, filas e idempotencia conforme o tipo de falha.
