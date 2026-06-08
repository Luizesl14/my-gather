import { z } from "zod";

export const organizationWorkspaceParamsSchema = z.object({
  organizationId: z.string().min(1),
});

export const workspaceParamsSchema = z.object({
  workspaceId: z.string().min(1),
});

export const createWorkspaceBodySchema = z.object({
  name: z.string().min(2).max(100),
});

const mapTileSchema = z.object({
  tile: z.string().min(1),
  x: z.number().int().min(0),
  y: z.number().int().min(0),
  rotation: z.number().int().optional(),
  flipX: z.boolean().optional(),
  w: z.number().int().min(1).optional(),
  h: z.number().int().min(1).optional(),
  frameCol: z.number().int().min(0).optional(),
  frameRow: z.number().int().min(0).optional(),
  frameCols: z.number().int().min(1).optional(),
  frameRows: z.number().int().min(1).optional(),
  overlayId: z.string().optional(),
});

const mapObjectSchema = z.object({
  id: z.string().min(1),
  asset: z.string().min(1),
  x: z.number().int().min(0),
  y: z.number().int().min(0),
  layer: z.number().int(),
});

const mapLayerSchema = z.object({
  name: z.string().min(1),
  tiles: z.array(mapTileSchema).default([]),
  objects: z.array(mapObjectSchema).default([]),
});

const mapZoneSchema = z.object({
  id: z.string().min(1),
  x: z.number().int().min(0),
  y: z.number().int().min(0),
  w: z.number().int().min(1),
  h: z.number().int().min(1),
});

const spawnSchema = z.object({
  x: z.number().int().min(0),
  y: z.number().int().min(0),
  direction: z.enum(["front", "back", "left", "right"]),
});

export const updateMapBodySchema = z.object({
  width: z.number().int().min(10).max(100),
  height: z.number().int().min(10).max(100),
  tileSize: z.number().int().default(32),
  assetPackId: z.string().default("office-scenary-v1"),
  spawn: spawnSchema.default({ x: 1, y: 1, direction: "front" }),
  layers: z.array(mapLayerSchema),
  collision: z.array(z.unknown()).default([]),
  interactiveZones: z.array(mapZoneSchema).default([]),
});
