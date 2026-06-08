import { randomUUID } from "node:crypto";

import { prisma } from "../../../../shared/infrastructure/database/prisma-client";
import { loadDefaultOfficeMap } from "../map/default-map-loader";
import { type WorkspaceRecord, type FloorRecord } from "./in-memory-workspace-repository";

export class PrismaWorkspaceRepository {
  private readonly _defaultMap = loadDefaultOfficeMap();

  async createWorkspace(input: {
    id: string;
    organizationId: string;
    name: string;
    activeFloorId: string;
  }): Promise<WorkspaceRecord> {
    const map = this._defaultMap;

    await prisma.workspace.create({
      data: {
        id: input.id,
        organizationId: input.organizationId,
        name: input.name,
        floors: {
          create: {
            id: input.activeFloorId,
            name: "Principal",
            level: 1,
            map: {
              create: {
                id: randomUUID(),
                assetPackId: map.assetPackId,
                tileSize: map.tileSize,
                width: map.width,
                height: map.height,
                layers: (map.layers ?? []) as object[],
                collision: (map.collision ?? []) as object[],
                interactiveZones: (map.interactiveZones ?? []) as object[],
              },
            },
          },
        },
      },
    });

    return { id: input.id, organizationId: input.organizationId, name: input.name, activeFloorId: input.activeFloorId };
  }

  async listByOrganization(organizationId: string): Promise<WorkspaceRecord[]> {
    const rows = await prisma.workspace.findMany({
      where: { organizationId },
      include: { floors: { take: 1, orderBy: { level: "asc" } } },
      orderBy: { createdAt: "asc" },
    });
    return rows.map((r) => ({
      id: r.id,
      organizationId: r.organizationId,
      name: r.name,
      activeFloorId: r.floors[0]?.id ?? "",
    }));
  }

  async findWorkspace(id: string): Promise<WorkspaceRecord | null> {
    const row = await prisma.workspace.findUnique({
      where: { id },
      include: { floors: { take: 1, orderBy: { level: "asc" } } },
    });
    if (!row) return null;
    return {
      id: row.id,
      organizationId: row.organizationId,
      name: row.name,
      activeFloorId: row.floors[0]?.id ?? "",
    };
  }

  async findActiveFloor(workspaceId: string): Promise<FloorRecord | null> {
    const row = await prisma.floor.findFirst({
      where: { workspaceId },
      orderBy: { level: "asc" },
    });
    if (!row) return null;
    return { id: row.id, workspaceId: row.workspaceId, name: row.name, level: row.level };
  }

  async findMap(workspaceId: string): Promise<object | null> {
    const floor = await prisma.floor.findFirst({
      where: { workspaceId },
      orderBy: { level: "asc" },
      include: { map: true },
    });
    return floor?.map ?? null;
  }

  async deleteWorkspace(workspaceId: string): Promise<void> {
    await prisma.workspace.delete({ where: { id: workspaceId } });
  }

  async updateMap(
    workspaceId: string,
    data: {
      width: number;
      height: number;
      tileSize: number;
      assetPackId: string;
      spawn: { x: number; y: number; direction: string };
      layers: object[];
      collision: object[];
      interactiveZones: object[];
    },
  ): Promise<void> {
    const floor = await prisma.floor.findFirst({
      where: { workspaceId },
      orderBy: { level: "asc" },
    });
    if (!floor) throw new Error("floor.not_found");

    await prisma.officeMap.upsert({
      where: { floorId: floor.id },
      create: {
        id: randomUUID(),
        floorId: floor.id,
        assetPackId: data.assetPackId,
        tileSize: data.tileSize,
        width: data.width,
        height: data.height,
        layers: data.layers,
        collision: data.collision,
        interactiveZones: data.interactiveZones,
      },
      update: {
        assetPackId: data.assetPackId,
        tileSize: data.tileSize,
        width: data.width,
        height: data.height,
        layers: data.layers,
        collision: data.collision,
        interactiveZones: data.interactiveZones,
        publishedAt: new Date(),
      },
    });
  }
}
