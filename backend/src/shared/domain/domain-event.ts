export type DomainEvent = {
  eventName: string;
  aggregateId: string;
  occurredAt: Date;
};

