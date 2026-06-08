import { type DomainEvent } from "../../../../shared/domain/domain-event";

export function workspaceCreated(workspaceId: string, occurredAt = new Date()): DomainEvent {
  return {
    eventName: "workspace.workspace_created",
    aggregateId: workspaceId,
    occurredAt,
  };
}

export function floorCreated(floorId: string, occurredAt = new Date()): DomainEvent {
  return {
    eventName: "workspace.floor_created",
    aggregateId: floorId,
    occurredAt,
  };
}

export function mapPublished(floorId: string, occurredAt = new Date()): DomainEvent {
  return {
    eventName: "workspace.map_published",
    aggregateId: floorId,
    occurredAt,
  };
}

export function roomCreated(roomId: string, occurredAt = new Date()): DomainEvent {
  return {
    eventName: "workspace.room_created",
    aggregateId: roomId,
    occurredAt,
  };
}

export function deskAssigned(deskId: string, occurredAt = new Date()): DomainEvent {
  return {
    eventName: "workspace.desk_assigned",
    aggregateId: deskId,
    occurredAt,
  };
}
