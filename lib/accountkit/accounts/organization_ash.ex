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
      accept [:name, :text_logo]
    end

    update :update do
      primary? true
      accept [:name, :text_logo]
    end

    read :list_for_platform do
      description "List all organizations for the platform control plane"
    end
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end

    policy action(:create) do
      authorize_if Accountkit.Accounts.Checks.NeedsOrganizationOnboarding
      authorize_if Accountkit.Accounts.Checks.PlatformOwner
    end

    policy action_type(:read) do
      authorize_if relates_to_actor_via([:memberships, :user])
      authorize_if Accountkit.Accounts.Checks.PlatformOwner
    end

    policy action_type([:update, :destroy]) do
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

    attribute :text_logo, :string do
      allow_nil? false
      public? true
      constraints trim?: true, allow_empty?: false, max_length: 32
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    has_many :memberships, Accountkit.Accounts.OrganizationMembership
    has_many :sso_applications, Accountkit.Accounts.SsoApplication
  end

  calculations do
    calculate :end_users_count, :integer, expr(0)
  end

  identities do
    identity :unique_name, [:name]
  end
end
