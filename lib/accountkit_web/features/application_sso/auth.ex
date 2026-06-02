defmodule AccountkitWeb.Features.ApplicationSso.Auth do
  @moduledoc """
  Password authentication operations for client-application end users.
  """

  alias Accountkit.Accounts.{EndUser, SsoApplication}

  def sign_in(%SsoApplication{} = application, params) do
    EndUser
    |> Ash.Query.for_read(
      :sign_in_with_password,
      %{
        sso_application_id: application.id,
        login_id: EndUser.login_id(application.id, params["email"]),
        password: params["password"]
      },
      authorize?: false
    )
    |> Ash.read_one()
    |> case do
      {:ok, %EndUser{} = end_user} -> {:ok, end_user}
      {:ok, nil} -> {:error, :invalid_credentials}
      {:error, _error} -> {:error, :invalid_credentials}
    end
  end

  def register(%SsoApplication{} = application, params) do
    EndUser
    |> Ash.Changeset.for_create(
      :register_with_password,
      %{
        sso_application_id: application.id,
        name: params["name"],
        email: params["email"],
        password: params["password"],
        password_confirmation: params["password"]
      },
      authorize?: false
    )
    |> Ash.create()
    |> case do
      {:ok, %EndUser{} = end_user} -> {:ok, end_user}
      {:error, error} -> {:error, classify_register_error(error)}
    end
  end

  def user_json(%EndUser{} = end_user) do
    %{
      id: end_user.id,
      name: end_user.name,
      email: to_string(end_user.email),
      phone: end_user.phone,
      authMethods: end_user.auth_methods,
      profileImageUrl: nil,
      authProvider: nil,
      ssoApplicationId: end_user.sso_application_id,
      createdAt: Map.get(end_user, :created_at)
    }
  end

  def client_json(%SsoApplication{} = application) do
    %{
      id: application.id,
      name: application.name,
      logoUrl: application.logo_url
    }
  end

  defp classify_register_error(error) do
    message = Exception.message(error)

    cond do
      String.contains?(message, "unique_email_per_application") or
          String.contains?(message, "has already been taken") ->
        :email_exists

      true ->
        :server_error
    end
  end
end
