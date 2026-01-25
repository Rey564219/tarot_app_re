BEGIN;

ALTER TABLE reading_interpretations
ADD COLUMN updated_at timestamptz NOT NULL DEFAULT now();

CREATE TABLE interpretation_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reading_id uuid NOT NULL REFERENCES readings(id),
  version int NOT NULL,
  prompt text,
  output_text text,
  model text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (reading_id, version)
);

CREATE INDEX interpretation_versions_reading_id_idx ON interpretation_versions (reading_id, version);

COMMIT;
