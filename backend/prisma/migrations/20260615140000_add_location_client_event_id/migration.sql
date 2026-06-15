-- AlterTable
ALTER TABLE "locations" ADD COLUMN "client_event_id" VARCHAR(36);

-- CreateIndex (dedupe idempotent mobile uploads)
CREATE UNIQUE INDEX "locations_device_id_client_event_id_key"
  ON "locations"("device_id", "client_event_id");
