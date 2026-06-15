-- Sprint 8: evidence photo metadata + local file storage path
CREATE TYPE "PhotoTrigger" AS ENUM (
    'SIM_REPLACEMENT',
    'REMOTE_COMMAND',
    'UNLOCK_FAILURE',
    'MANUAL'
);

CREATE TABLE "photos" (
    "id" UUID NOT NULL,
    "device_id" UUID NOT NULL,
    "client_event_id" VARCHAR(36),
    "trigger" "PhotoTrigger" NOT NULL,
    "storage_path" VARCHAR(500) NOT NULL,
    "mime_type" VARCHAR(64) NOT NULL,
    "file_size" INTEGER NOT NULL,
    "captured_at" TIMESTAMPTZ NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "photos_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "photos_device_id_client_event_id_key"
    ON "photos"("device_id", "client_event_id");

CREATE INDEX "photos_device_id_captured_at_idx"
    ON "photos"("device_id", "captured_at");

ALTER TABLE "photos"
    ADD CONSTRAINT "photos_device_id_fkey"
    FOREIGN KEY ("device_id") REFERENCES "devices"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;
