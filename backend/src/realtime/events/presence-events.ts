import { z } from "zod";

const directionSchema = z.enum(["front", "back", "left", "right"]);
const motionStateSchema = z.enum(["idle", "walking"]);

// ─── Client → Server ──────────────────────────────────────────────────────────

export const workspaceJoinSchema = z.object({
  type: z.literal("workspace:join"),
  workspaceId: z.string().min(1),
  floorId: z.string().optional(),
  characterId: z.string().optional(),
});

export const workspaceLeaveSchema = z.object({
  type: z.literal("workspace:leave"),
});

export const avatarMoveSchema = z.object({
  type: z.literal("avatar:move"),
  x: z.number(),
  y: z.number(),
  direction: directionSchema,
  motionState: motionStateSchema,
});

export const avatarStopSchema = z.object({
  type: z.literal("avatar:stop"),
  x: z.number(),
  y: z.number(),
  direction: directionSchema,
});

export const presenceStatusChangeSchema = z.object({
  type: z.literal("presence:status.change"),
  status: z.string().min(1),
  emoji: z.string().nullable().optional(),
  text: z.string().nullable().optional(),
});

export type WorkspaceJoinEvent = z.infer<typeof workspaceJoinSchema>;
export type WorkspaceLeaveEvent = z.infer<typeof workspaceLeaveSchema>;
export type AvatarMoveEvent = z.infer<typeof avatarMoveSchema>;
export type AvatarStopEvent = z.infer<typeof avatarStopSchema>;
export type PresenceStatusChangeEvent = z.infer<typeof presenceStatusChangeSchema>;

export const presenceProfileChangeSchema = z.object({
  type: z.literal("presence:profile.change"),
  displayName: z.string().min(1).max(60),
  role: z.string().max(40).default(""),
  team: z.string().max(40).default(""),
});

export type PresenceProfileChangeEvent = z.infer<typeof presenceProfileChangeSchema>;

export function presenceProfileChangedPayload(
  userId: string,
  displayName: string,
  role: string,
  team: string,
) {
  return JSON.stringify({ type: "presence:profile.changed", userId, displayName, role, team });
}

// ─── Server → Client builders ─────────────────────────────────────────────────

export function rosterPayload(members: Array<{
  userId: string;
  displayName: string;
  characterId: string;
  x: number;
  y: number;
  direction: string;
  motionState: string;
  presenceStatus: string;
  role?: string;
  team?: string;
}>) {
  return JSON.stringify({ type: "workspace:roster", users: members });
}

export function userJoinedPayload(
  userId: string,
  displayName: string,
  characterId: string,
  x: number,
  y: number,
  direction: string,
  motionState: string,
  presenceStatus: string,
  role = "",
  team = "",
) {
  return JSON.stringify({ type: "workspace:user.joined", userId, displayName, characterId, x, y, direction, motionState, presenceStatus, role, team });
}

export function userLeftPayload(userId: string) {
  return JSON.stringify({ type: "workspace:user.left", userId });
}

export function avatarMovedPayload(
  userId: string,
  x: number,
  y: number,
  direction: string,
  motionState: string,
) {
  return JSON.stringify({ type: "avatar:moved", userId, x, y, direction, motionState });
}

export function presenceStatusChangedPayload(
  userId: string,
  status: string,
  emoji: string | null,
  text: string | null,
) {
  return JSON.stringify({ type: "presence:status.changed", userId, status, emoji, text });
}
