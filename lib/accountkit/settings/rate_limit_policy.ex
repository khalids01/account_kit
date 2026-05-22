defmodule Accountkit.Settings.RateLimitPolicy do
  @moduledoc """
  Configurable rate limit policies for auth and other sensitive actions.
  """
  use Ash.Resource,
    otp_app: :accountkit,
    domain: Accountkit.Settings,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "rate_limit_policies"
    repo Accountkit.Repo
  end

  actions do
    defaults [:read]

    read :list_all do
      prepare build(sort: [key: :asc])
    end

    update :update do
      accept [:limit, :period_seconds, :enabled, :description]
      require_atomic? false
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :key, :string do
      allow_nil? false
      public? true
    end

    attribute :limit, :integer do
      allow_nil? false
      public? true
    end

    attribute :period_seconds, :integer do
      allow_nil? false
      public? true
    end

    attribute :enabled, :boolean do
      allow_nil? false
      default true
      public? true
    end

    attribute :description, :string do
      public? true
    end
  end

  identities do
    identity :unique_key, [:key]
  end
end
