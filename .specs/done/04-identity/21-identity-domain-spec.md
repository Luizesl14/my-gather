# 21 — Identity Domain Spec

## Objetivo

Implementar domínio de usuários, organizações, membros e convites.

## Entidades

- `User`
- `Organization`
- `Membership`
- `Invitation`

## Value Objects

- `Email`
- `PasswordHash`
- `DisplayName`
- `OrganizationName`
- `RoleName`
- `InvitationToken`

## Eventos

- `UserRegistered`
- `OrganizationCreated`
- `InvitationCreated`
- `InvitationAccepted`
- `MemberJoinedOrganization`

## Critérios de aceite

- Email inválido falha no domínio.
- Organização exige nome válido.
- Convite expirado não pode ser aceito.
