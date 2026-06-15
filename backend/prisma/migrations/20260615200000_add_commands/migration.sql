-- CreateEnum
CREATE TYPE "CommandType" AS ENUM ('ACTIVATE_THEFT_MODE', 'REQUEST_LIVE_LOCATION', 'TRIGGER_ALARM', 'CAPTURE_IMAGE');

-- CreateEnum
CREATE TYPE "CommandStatus" AS ENUM ('PENDING', 'DELIVERED', 'ACKNOWLEDGED', 'FAILED', 'EXPIRED');

-- CreateTable
CREATE TABLE "commands" (
    "id" UUID NOT NULL,
    "device_id" UUID NOT NULL,
    "issued_by_id" UUID NOT NULL,
    "client_event_id" VARCHAR(36),
    "type" "CommandType" NOT NULL,
    "status" "CommandStatus" NOT NULL DEFAULT 'PENDING',
    "payload" JSONB,
    "issued_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "delivered_at" TIMESTAMPTZ,
    "completed_at" TIMESTAMPTZ,
    "error_message" VARCHAR(500),
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "commands_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "commands_device_id_issued_at_idx" ON "commands"("device_id", "issued_at");

-- CreateIndex
CREATE INDEX "commands_status_idx" ON "commands"("status");

-- CreateIndex
CREATE UNIQUE INDEX "commands_device_id_client_event_id_key" ON "commands"("device_id", "client_event_id");

-- AddForeignKey
ALTER TABLE "commands" ADD CONSTRAINT "commands_device_id_fkey" FOREIGN KEY ("device_id") REFERENCES "devices"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "commands" ADD CONSTRAINT "commands_issued_by_id_fkey" FOREIGN KEY ("issued_by_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
