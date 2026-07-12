-- Campos de perfil exibidos na etiqueta do avatar (função | equipe)
ALTER TABLE "users" ADD COLUMN "role" TEXT NOT NULL DEFAULT '';
ALTER TABLE "users" ADD COLUMN "team" TEXT NOT NULL DEFAULT '';
