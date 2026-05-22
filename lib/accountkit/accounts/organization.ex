defmodule Accountkit.Accounts.Organization do
  use Ash.Resource,
    otp_app: :accountkit,
    domain: Accountkit.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "organizations"
    repo Accountkit.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:name]
    end

    update :update do
      primary? true
      accept [:name]
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

    attribute :name, :string do
      allow_nil? false
      public? true
      constraints trim?: true, allow_empty?: false
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    has_many :memberships, Accountkit.Accounts.OrganizationMembership
  end

  identities do
    identity :unique_name, [:name]
  end
end
