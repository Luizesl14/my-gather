export abstract class ValueObject<Props> {
  protected constructor(protected readonly props: Props) {}

  equals(other?: ValueObject<Props>): boolean {
    if (!other) return false;
    if (this === other) return true;
    return JSON.stringify(this.props) === JSON.stringify(other.props);
  }
}

