export abstract class Entity<Props> {
  protected constructor(
    readonly id: string,
    protected readonly props: Props,
  ) {}

  equals(other?: Entity<Props>): boolean {
    if (!other) return false;
    if (this === other) return true;
    return this.id === other.id;
  }
}

