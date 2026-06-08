import { type DomainEvent } from "../../../../shared/domain/domain-event";

export function userRegistered(userId: string, occurredAt = new Date()): DomainEvent {
  return {
    eventName: "identity.user_registered",
    aggregateId: userId,
    occurredAt,
  };
}

export function organizationCreated(
  organizationId: string,
  occurredAt = new Date(),
): DomainEvent {
  return {
    eventName: "identity.organization_created",
    aggregateId: organizationId,
    occurredAt,
  };
}

export function invitationCreated(invitationId: string, occurredAt = new Date()): DomainEvent {
  return {
    eventName: "identity.invitation_created",
    aggregateId: invitationId,
    occurredAt,
  };
}

export function invitationAccepted(invitationId: string, occurredAt = new Date()): DomainEvent {
  return {
    eventName: "identity.invitation_accepted",
    aggregateId: invitationId,
    occurredAt,
  };
}

export function memberJoinedOrganization(
  membershipId: string,
  occurredAt = new Date(),
): DomainEvent {
  return {
    eventName: "identity.member_joined_organization",
    aggregateId: membershipId,
    occurredAt,
  };
}
