-- Sprint 6: SIM change event log
CREATE TABLE "sim_changes" (
    "id" UUID NOT NULL,
    "device_id" UUID NOT NULL,
    "client_event_id" VARCHAR(36),
    "previous_serial" VARCHAR(40),
    "new_serial" VARCHAR(40),
    "previous_operator" VARCHAR(60),
    "new_operator" VARCHAR(60),
    "detected_at" TIMESTAMPTZ NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "sim_changes_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "sim_changes_device_id_client_event_id_key"
    ON "sim_changes"("device_id", "client_event_id");

CREATE INDEX "sim_changes_device_id_detected_at_idx"
    ON "sim_changes"("device_id", "detected_at");

ALTER TABLE "sim_changes"
    ADD CONSTRAINT "sim_changes_device_id_fkey"
    FOREIGN KEY ("device_id") REFERENCES "devices"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;
