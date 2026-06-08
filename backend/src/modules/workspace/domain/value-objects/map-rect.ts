import { Result } from "../../../../shared/domain/result";
import { MapSize } from "./map-size";

export class MapRect {
  private constructor(
    readonly x: number,
    readonly y: number,
    readonly width: number,
    readonly height: number,
  ) {}

  static create(input: {
    x: number;
    y: number;
    width: number;
    height: number;
  }): Result<MapRect, string> {
    if (input.x < 0 || input.y < 0 || input.width <= 0 || input.height <= 0) {
      return Result.err("workspace.map_rect.invalid");
    }

    return Result.ok(new MapRect(input.x, input.y, input.width, input.height));
  }

  fitsInside(size: MapSize): boolean {
    return this.x + this.width <= size.width && this.y + this.height <= size.height;
  }
}
