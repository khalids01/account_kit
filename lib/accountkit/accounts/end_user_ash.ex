defmodule Accountkit.Accounts.EndUser do
  use Ash.Resource,
    otp_app: :accountkit,
    domain: Accountkit.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshAuthentication]

  authentication do
    subject_name :end_user

    tokens do
      enabled? true
      token_resource Accountkit.Accounts.EndUserToken
      signing_secret Accountkit.Secrets
      store_all_tokens? true
      require_token_presence_for_authentication? true
    end

    strategies do
      password :password do
        identity_field :login_id
        hash_provider AshAuthentication.BcryptProvider
      end
    end
  end

  postgres do
    table "end_users"
    repo Accountkit.Repo
    migration_defaults auth_methods: ~s(["password"])
  end

  actions do
    defaults [:read, :destroy]

    read :get_by_id do
      description "Get an application end user by id."
      get_by :id
    end

    read :get_by_subject do
      description "Get an application end user by the subject claim in a JWT"
      argument :subject, :string, allow_nil?: false
      get? true
      prepare AshAuthentication.Preparations.FilterBySubject
    end

    read :sign_in_with_password do
      description "Attempt to sign in an application end user using email and password."
      get? true

      argument :sso_application_id, :uuid do
        allow_nil? false
      end

      argument :login_id, :ci_string do
        allow_nil? false
        sensitive? true
      end

      argument :password, :string do
        allow_nil? false
        sensitive? true
      end

      filter expr(
               sso_application_id == ^arg(:sso_application_id) and is_nil(banned_at) and
                 is_nil(archived_at)
             )

      prepare AshAuthentication.Strategy.Password.SignInPreparation

      metadata :token, :string do
        description "A JWT that can be used to authenticate the application end user."
        allow_nil? false
      end
    end

    create :register_with_password do
      description "Register an application end user with email and password."

      argument :sso_application_id, :uuid do
        allow_nil? false
      end

      argument :name, :string do
        allow_nil? false
      end

      argument :email, :ci_string do
        allow_nil? false
      end

      argument :password, :string do
        allow_nil? false
        constraints min_length: 8
        sensitive? true
      end

      argument :password_confirmation, :string do
        allow_nil? false
        sensitive? true
      end

      change set_attribute(:sso_application_id, arg(:sso_application_id))
      change set_attribute(:name, arg(:name))
      change set_attribute(:email, arg(:email))
      change set_attribute(:auth_methods, ["password"])
      change &set_login_id/2
      change AshAuthentication.Strategy.Password.HashPasswordChange
      change AshAuthentication.GenerateTokenChange

      validate AshAuthentication.Strategy.Password.PasswordConfirmationValidation

      metadata :token, :string do
        description "A JWT that can be used to authenticate the application end user."
        allow_nil? false
      end
    end

    update :update_profile do
      accept [:name, :phone]
    end

    update :ban do
      require_atomic? false
      accept []

      change fn changeset, _context ->
        Ash.Changeset.force_change_attribute(changeset, :banned_at, DateTime.utc_now())
      end
    end

    update :unban do
      accept []
      change set_attribute(:banned_at, nil)
    end

    update :archive do
      require_atomic? false
      accept []

      change fn changeset, _context ->
        Ash.Changeset.force_change_attribute(changeset, :archived_at, DateTime.utc_now())
      end
    end

    update :restore do
      accept []
      change set_attribute(:archived_at, nil)
    end
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end

    policy action_type(:read) do
      authorize_if expr(id == ^actor(:id))
      authorize_if Accountkit.Accounts.Checks.PlatformOwner

      authorize_if expr(
                     exists(
                       sso_application.organization.memberships,
                       user_id == ^actor(:id) and role == :org_admin
                     )
                   )
    end

    policy action_type([:update, :destroy]) do
      authorize_if Accountkit.Accounts.Checks.PlatformOwner

      authorize_if expr(
                     exists(
                       sso_application.organization.memberships,
                       user_id == ^actor(:id) and role == :org_admin
                     )
                   )
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
      constraints trim?: true, allow_empty?: false
    end

    attribute :email, :ci_string do
      allow_nil? false
      public? true
    end

    attribute :phone, :string do
      public? true
      constraints trim?: true
    end

    attribute :login_id, :ci_string do
      allow_nil? false
      public? true
      sensitive? true
    end

    attribute :hashed_password, :string do
      sensitive? true
    end

    attribute :confirmed_at, :utc_datetime_usec

    attribute :banned_at, :utc_datetime_usec do
      public? true
    end

    attribute :archived_at, :utc_datetime_usec do
      public? true
    end

    attribute :auth_methods, {:array, :string} do
      allow_nil? false
      default ["password"]
      public? true
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :sso_application, Accountkit.Accounts.SsoApplication do
      allow_nil? false
      public? true
    end
  end

  identities do
    identity :unique_login_id, [:login_id]
    identity :unique_email_per_application, [:sso_application_id, :email]
  end

  def set_login_id(changeset, _context) do
    sso_application_id = Ash.Changeset.get_argument(changeset, :sso_application_id)
    email = Ash.Changeset.get_argument(changeset, :email)

    Ash.Changeset.force_change_attribute(
      changeset,
      :login_id,
      login_id(sso_application_id, email)
    )
  end

  def login_id(sso_application_id, email) do
    "#{sso_application_id}:#{Accountkit.Auth.Email.normalize(email)}"
  end
end
