defmodule Accountkit.Accounts.ApiKey do
  use Ash.Resource,
    otp_app: :accountkit,
    domain: Accountkit.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "api_keys"
    repo Accountkit.Repo
  end

  actions do
    defaults [:read, :destroy]

    read :list_for_user do
      argument :user_id, :uuid, allow_nil?: false

      filter expr(user_id == ^arg(:user_id))
      prepare build(sort: [expires_at: :asc])
    end

    create :create do
      primary? true
      accept [:user_id, :expires_at]

      change {AshAuthentication.Strategy.ApiKey.GenerateApiKey,
              prefix: :accountkit, hash: :api_key_hash}
    end
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end

    policy action_type(:read) do
      authorize_if expr(user_id == ^actor(:id))
    end

    policy action(:create) do
      authorize_if expr(user_id == ^actor(:id))
    end

    policy action_type(:destroy) do
      authorize_if expr(user_id == ^actor(:id))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :api_key_hash, :binary do
      allow_nil? false
      sensitive? true
    end

    attribute :expires_at, :utc_datetime_usec do
      allow_nil? false
    end
  end

  relationships do
    belongs_to :user, Accountkit.Accounts.User
  end

  calculations do
    calculate :valid, :boolean, expr(expires_at > now())
  end

  identities do
    identity :unique_api_key, [:api_key_hash]
  end
end
