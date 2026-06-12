import { z } from "zod";

// ─── Client → server events ──────────────────────────────────────────────────

export const joinEventSchema = z.object({
  type: z.literal("join"),
  workspaceId: z.string().min(1),
});

export const statusEventSchema = z.object({
  type: z.literal("status"),
  presenceId: z.string().min(1),
  emoji: z.string().nullable().optional(),
  text: z.string().nullable().optional(),
});

export const reactionEventSchema = z.object({
  type: z.literal("reaction"),
  sprite: z.string().min(1),
  targetUserId: z.string().nullable().optional(),
});

export const callInviteEventSchema = z.object({
  type: z.literal("call:invite"),
  toUserId: z.string().min(1),
  mode: z.enum(["video", "audio"]),
});

export const callAcceptEventSchema = z.object({
  type: z.literal("call:accept"),
  toUserId: z.string().min(1),
  mode: z.enum(["video", "audio"]),
});

export const callDeclineEventSchema = z.object({
  type: z.literal("call:decline"),
  toUserId: z.string().min(1),
});

export const callEndEventSchema = z.object({
  type: z.literal("call:end"),
  toUserId: z.string().min(1),
});

// WebRTC signaling relay (SDP offers/answers and ICE candidates).
export const rtcSignalEventSchema = z.object({
  type: z.literal("rtc:signal"),
  toUserId: z.string().min(1),
  data: z.unknown(),
});

export type JoinEvent = z.infer<typeof joinEventSchema>;
export type StatusEvent = z.infer<typeof statusEventSchema>;
export type ReactionEvent = z.infer<typeof reactionEventSchema>;
export type CallInviteEvent = z.infer<typeof callInviteEventSchema>;
export type CallAcceptEvent = z.infer<typeof callAcceptEventSchema>;
export type CallDeclineEvent = z.infer<typeof callDeclineEventSchema>;
export type CallEndEvent = z.infer<typeof callEndEventSchema>;
export type RtcSignalEvent = z.infer<typeof rtcSignalEventSchema>;

// ─── Server → client payload builders ────────────────────────────────────────

export type RosterUser = {
  id: string;
  displayName: string;
  avatarId: string;
  presenceId: string;
  emoji: string | null;
  text: string | null;
};

export function rosterEvent(users: RosterUser[]) {
  return { type: "roster", users } as const;
}

export function peerReactionEvent(
  fromUserId: string,
  fromName: string,
  sprite: string,
  targetUserId: string | null,
) {
  return { type: "reaction", fromUserId, fromName, sprite, targetUserId } as const;
}

export function callIncomingEvent(fromUserId: string, fromName: string, mode: "video" | "audio") {
  return { type: "call:incoming", fromUserId, fromName, mode } as const;
}

export function callAcceptedEvent(fromUserId: string, mode: "video" | "audio") {
  return { type: "call:accepted", fromUserId, mode } as const;
}

export function callDeclinedEvent(fromUserId: string) {
  return { type: "call:declined", fromUserId } as const;
}

export function callEndedEvent(fromUserId: string) {
  return { type: "call:ended", fromUserId } as const;
}

export function rtcSignalRelayEvent(fromUserId: string, data: unknown) {
  return { type: "rtc:signal", fromUserId, data } as const;
}
