import { type DomainEvent } from "./domain-event";
import { Entity } from "./entity";

export abstract class AggregateRoot<Props> extends Entity<Props> {
  private domainEvents: DomainEvent[] = [];

  getDomainEvents(): DomainEvent[] {
    return [...this.domainEvents];
  }

  protected addDomainEvent(event: DomainEvent): void {
    this.domainEvents.push(event);
  }

  clearDomainEvents(): void {
    this.domainEvents = [];
  }
}

