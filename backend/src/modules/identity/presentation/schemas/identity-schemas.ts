import { z } from "zod";

export const registerBodySchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
  displayName: z.string().min(2).max(80),
});

export const loginBodySchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

export const createOrganizationBodySchema = z.object({
  name: z.string().min(2).max(100),
});

export const inviteMemberBodySchema = z.object({
  email: z.string().email(),
  role: z.enum(["admin", "member"]),
});

export const acceptInvitationParamsSchema = z.object({
  token: z.string().min(16),
});

export const organizationParamsSchema = z.object({
  id: z.string().min(1),
});
