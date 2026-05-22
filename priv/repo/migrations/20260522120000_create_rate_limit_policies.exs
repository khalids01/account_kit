defmodule Accountkit.Repo.Migrations.CreateRateLimitPolicies do
  use Ecto.Migration

  def up do
    create table(:rate_limit_policies, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :key, :text, null: false
      add :limit, :integer, null: false
      add :period_seconds, :integer, null: false
      add :enabled, :boolean, null: false, default: true
      add :description, :text

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:rate_limit_policies, [:key])

    flush()

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    for {key, limit, period_seconds, description} <- default_policies() do
      repo().query!(
        """
        INSERT INTO rate_limit_policies (id, key, "limit", period_seconds, enabled, description, inserted_at, updated_at)
        VALUES (gen_random_uuid(), $1, $2, $3, true, $4, $5, $5)
        ON CONFLICT (key) DO NOTHING
        """,
        [key, limit, period_seconds, description, now]
      )
    end
  end

  def down do
    drop table(:rate_limit_policies)
  end

  defp default_policies do
    [
      {"magic_link_sign_in_ip", 5, 900, "Magic link sign-in attempts per IP (15 min window)"},
      {"magic_link_sign_in_email", 3, 900,
       "Magic link sign-in attempts per email (15 min window)"},
      {"magic_link_sign_up_ip", 5, 900, "Magic link sign-up attempts per IP (15 min window)"},
      {"magic_link_sign_up_email", 3, 900,
       "Magic link sign-up attempts per email (15 min window)"}
    ]
  end
end
