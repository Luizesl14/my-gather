# Arquitetura e Estratégia de Deploy do Aplicativo

## Visão Geral

Este projeto utiliza uma arquitetura moderna separando:

* Aplicativo mobile/web em Flutter
* Backend API em Fastify + Node.js
* Banco PostgreSQL gerenciado
* Armazenamento de arquivos compatível com S3
* Infraestrutura com VPS + Cloudflare

Objetivo: manter baixo custo, fácil manutenção e possibilidade de crescimento.

---

# Stack de Tecnologias

## Frontend

### Flutter

Responsável pelo aplicativo:

* Android
* iOS
* Flutter Web

Tecnologias:

* Flutter
* Dart

Código hospedado:

```
GitHub Repository
    |
    └── flutter-app
```

---

# Backend

## Fastify + Node.js

Responsável por:

* API REST
* Autenticação
* Regras de negócio
* Comunicação com banco
* Upload de arquivos
* Integrações externas

Stack:

* Node.js
* Fastify
* TypeScript
* Prisma ou Drizzle ORM
* Zod para validações
* JWT para autenticação

Código hospedado:

```
GitHub Repository
    |
    └── backend-api
```

---

# Banco de Dados

## Neon PostgreSQL

Responsável pelo armazenamento dos dados:

* Usuários
* Configurações
* Dados da aplicação
* Relacionamentos

Não será hospedado na VPS.

Conexão:

```
Fastify API
      |
      |
      v
Neon PostgreSQL
```

Vantagens:

* Banco gerenciado
* Backup
* Escalabilidade
* Sem manutenção manual

---

# Armazenamento de Arquivos

## Cloudflare R2

Substitui o Amazon S3.

Responsável por:

* Fotos
* Documentos
* Arquivos enviados pelo usuário

Fluxo:

```
Flutter App
      |
      |
Fastify API
      |
      |
Cloudflare R2
```

---

# Infraestrutura

## Hostinger VPS

Responsável pelo backend.

Configuração:

* Ubuntu
* Docker
* Docker Compose
* Nginx

Servidor:

```
Hostinger VPS

├── Nginx
│
└── Docker
      |
      └── Fastify API
```

---

# Cloudflare

A Cloudflare será usada como camada de internet.

Responsabilidades:

## DNS

Gerenciar domínios:

Exemplo:

```
api.meuapp.com
        |
        v
Hostinger VPS
```

---

## CDN

Entrega rápida de arquivos:

* Flutter Web
* Imagens
* Arquivos públicos

---

## Segurança

Responsável por:

* SSL
* Proteção contra ataques
* Firewall básico
* Proxy reverso

---

# Arquitetura Final

```
                 Usuário
                    |
                    |
              Cloudflare
                    |
       -------------------------
       |                       |
       |                       |
 Flutter Web              API Fastify
 Cloudflare Pages          Hostinger VPS
                                |
                                |
                         Docker Container
                                |
              --------------------------------
              |                              |
              v                              v
        Neon PostgreSQL              Cloudflare R2
```

---

# Estrutura dos Repositórios GitHub

## Frontend

```
flutter-app/

├── lib/
├── assets/
├── pubspec.yaml
└── README.md
```

---

## Backend

```
backend-api/

├── src/
├── prisma/
├── Dockerfile
├── docker-compose.yml
├── package.json
└── README.md
```

---

# Processo de Deploy

## 1. Desenvolvimento Local

Desenvolvimento:

```
Flutter
   |
   |
Fastify API
   |
   |
Neon PostgreSQL
```

Variáveis de ambiente:

Backend:

```
DATABASE_URL=
JWT_SECRET=
R2_ACCESS_KEY=
R2_SECRET_KEY=
R2_BUCKET=
R2_ENDPOINT=
```

---

# 2. Push para GitHub

Fluxo:

```
Developer

    |
    |
    v

Git Commit

    |
    |
    v

GitHub Repository
```

---

# 3. Deploy Backend

Na VPS:

Instalar:

* Docker
* Docker Compose
* Nginx

Clonar projeto:

```
git clone repository
```

Criar imagem:

```
docker compose build
```

Subir API:

```
docker compose up -d
```

Resultado:

```
Fastify rodando na VPS
```

---

# 4. Atualização do Backend

Novo código:

```
git push
```

Servidor:

```
git pull

docker compose build

docker compose up -d
```

API atualizada.

---

# 5. Deploy Flutter Web

Gerar build:

```
flutter build web
```

Enviar pasta:

```
build/web
```

para:

```
Cloudflare Pages
```

Deploy automático:

```
GitHub
   |
   |
Cloudflare Pages
```

---

# 6. Aplicativo Mobile

Android:

```
Flutter Build APK/AAB

Google Play Console
```

iOS:

```
Flutter Build IPA

Apple App Store
```

---

# Estratégia de Crescimento

Inicial:

```
Hostinger VPS
Neon Free
Cloudflare Free
R2 Free
```

Custo aproximado:

```
R$ 43/mês
```

---

Crescimento:

Adicionar:

* Redis
* Filas
* Mais containers
* CDN avançada
* Banco Neon pago

Sem alterar a arquitetura principal.

---

# Objetivo

Criar uma plataforma:

* barata para iniciar;
* simples de manter;
* segura;
* preparada para escalar;
* sem dependência de um único fornecedor.
