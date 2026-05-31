defmodule Accountkit.Repo.Migrations.FixSsoApplicationsCreatedAt do
  use Ecto.Migration

  def up do
    execute """
    DO $$
    BEGIN
      IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'sso_applications'
          AND column_name = 'inserted_at'
      ) AND NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'sso_applications'
          AND column_name = 'created_at'
      ) THEN
        ALTER TABLE public.sso_applications RENAME COLUMN inserted_at TO created_at;
      ELSIF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'sso_applications'
          AND column_name = 'created_at'
      ) THEN
        ALTER TABLE public.sso_applications
          ADD COLUMN created_at timestamp(6) without time zone NOT NULL DEFAULT (now() AT TIME ZONE 'utc');
      END IF;
    END
    $$;
    """
  end

  def down do
    execute """
    DO $$
    BEGIN
      IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'sso_applications'
          AND column_name = 'created_at'
      ) AND NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'sso_applications'
          AND column_name = 'inserted_at'
      ) THEN
        ALTER TABLE public.sso_applications RENAME COLUMN created_at TO inserted_at;
      END IF;
    END
    $$;
    """
  end
end
