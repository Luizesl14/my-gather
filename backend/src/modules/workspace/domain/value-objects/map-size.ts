import { Result } from "../../../../shared/domain/result";

export class MapSize {
  private constructor(
    readonly width: number,
    readonly height: number,
    readonly tileSize: number,
  ) {}

  static create(input: {
    width: number;
    height: number;
    tileSize: number;
  }): Result<MapSize, string> {
    if (input.width <= 0 || input.height <= 0 || input.tileSize <= 0) {
      return Result.err("workspace.map_size.invalid");
    }

    return Result.ok(new MapSize(input.width, input.height, input.tileSize));
  }
}
