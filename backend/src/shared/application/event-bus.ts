import { type DomainEvent } from "../domain/domain-event";

export interface EventBus {
  publish(events: DomainEvent[]): Promise<void>;
}

