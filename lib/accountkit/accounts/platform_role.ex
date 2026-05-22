defmodule Accountkit.Accounts.PlatformRole do
  use Ash.Resource,
    otp_app: :accountkit,
    domain: Accountkit.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "platform_roles"
    repo Accountkit.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:user_id, :role]
    end

    read :get_by_user_and_role do
      get? true

      argument :user_id, :uuid do
        allow_nil? false
      end

      argument :role, :atom do
        allow_nil? false
        constraints one_of: [:platform_owner]
      end

      filter expr(user_id == ^arg(:user_id) and role == ^arg(:role))
    end
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end

    policy always() do
      authorize_if Accountkit.Accounts.Checks.PlatformOwner
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :role, :atom do
      allow_nil? false
      public? true
      constraints one_of: [:platform_owner]
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :user, Accountkit.Accounts.User do
      allow_nil? false
    end
  end

  identities do
    identity :unique_user_platform_role, [:user_id, :role]
  end
end
