defmodule Accountkit.Repo.Migrations.MigrateResources1 do
  @moduledoc """
  Ash codegen migration for `rate_limit_policies`.

  The table was already created by
  `20260522120000_create_rate_limit_policies.exs`, so this migration is a no-op.
  It exists so Ecto/Ash migration history stays in sync with the resource snapshot.
  """

  use Ecto.Migration

  def up, do: :ok

  def down, do: :ok
end
