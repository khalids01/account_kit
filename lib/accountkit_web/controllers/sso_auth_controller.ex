defmodule AccountkitWeb.SsoAuthController do
  use AccountkitWeb, :controller

  alias Accountkit.Accounts.User
  alias Accountkit.Sso

  def options(conn, _params) do
    conn
    |> put_cors_headers()
    |> send_resp(204, "")
  end

  def validate_client(conn, params) do
    with {:ok, _application} <-
           Sso.validate_client(params["token"], params["redirectUrl"], params["clientOrigin"]) do
      conn
      |> put_cors_headers()
      |> json(%{success: true})
    else
      {:error, reason} -> legacy_error(conn, reason, simple?: true)
    end
  end

  def client_info(conn, %{"token" => token}) do
    with {:ok, application} <- Sso.get_application_by_token(token),
         :ok <- Sso.ensure_active(application) do
      conn
      |> put_cors_headers()
      |> json(Sso.public_client(application))
    else
      {:error, reason} -> legacy_error(conn, reason, simple?: true)
    end
  end

  def client_info(conn, _params), do: legacy_error(conn, :missing_token, simple?: true)

  def login(conn, params) do
    with :ok <- require_param(params, "email", :missing_email),
         :ok <- require_param(params, "password", :missing_password),
         {:ok, application} <- validate_password_client(params),
         {:ok, user} <- sign_in(params) do
      auth_success(conn, user, application)
    else
      {:error, reason} -> legacy_error(conn, reason)
    end
  end

  def register(conn, params) do
    with :ok <- require_param(params, "name", :missing_name),
         :ok <- require_param(params, "email", :missing_email),
         :ok <- require_param(params, "password", :missing_password),
         :ok <- validate_password_length(params["password"]),
         {:ok, application} <- validate_password_client(params),
         {:ok, user} <- register_user(params) do
      auth_success(conn, user, application)
    else
      {:error, reason} -> legacy_error(conn, reason)
    end
  end

  def user(conn, _params) do
    case conn.assigns[:current_user] do
      %User{} = user ->
        conn
        |> put_cors_headers()
        |> json(%{success: true, user: user_json(user)})

      _user ->
        legacy_error(conn, :invalid_token)
    end
  end

  defp validate_password_client(params) do
    with {:ok, application} <- Sso.validate_client(params["token"], params["redirectUrl"]) do
      if application.password_enabled do
        {:ok, application}
      else
        {:error, :password_disabled}
      end
    end
  end

  defp sign_in(params) do
    User
    |> Ash.Query.for_read(
      :sign_in_with_password,
      %{email: params["email"], password: params["password"]},
      authorize?: false
    )
    |> Ash.read_one()
    |> case do
      {:ok, %User{} = user} -> {:ok, user}
      {:ok, nil} -> {:error, :invalid_credentials}
      {:error, _error} -> {:error, :invalid_credentials}
    end
  end

  defp register_user(params) do
    User
    |> Ash.Changeset.for_create(
      :register_with_password,
      %{
        name: params["name"],
        email: params["email"],
        password: params["password"],
        password_confirmation: params["password"]
      },
      authorize?: false
    )
    |> Ash.create()
    |> case do
      {:ok, %User{} = user} -> {:ok, user}
      {:error, error} -> {:error, classify_register_error(error)}
    end
  end

  defp auth_success(conn, user, application) do
    conn
    |> put_cors_headers()
    |> json(%{
      success: true,
      token: user.__metadata__.token,
      user: user_json(user),
      client: client_json(application)
    })
  end

  defp user_json(%User{} = user) do
    %{
      id: user.id,
      name: user.name,
      email: to_string(user.email),
      profileImageUrl: nil,
      authProvider: nil,
      createdAt: Map.get(user, :created_at)
    }
  end

  defp client_json(application) do
    %{
      id: application.id,
      name: application.name,
      logoUrl: application.logo_url
    }
  end

  defp require_param(params, key, reason) do
    case Map.get(params, key) do
      value when is_binary(value) and value != "" -> :ok
      _value -> {:error, reason}
    end
  end

  defp validate_password_length(password) when is_binary(password) and byte_size(password) >= 8,
    do: :ok

  defp validate_password_length(_password), do: {:error, :password_too_short}

  defp classify_register_error(error) do
    message = Exception.message(error)

    cond do
      String.contains?(message, "unique_email") or
          String.contains?(message, "has already been taken") ->
        :email_exists

      true ->
        :server_error
    end
  end

  defp legacy_error(conn, :missing_email, _opts) do
    json_error(conn, 400, "Email is required", "MISSING_EMAIL")
  end

  defp legacy_error(conn, :missing_password, _opts) do
    json_error(conn, 400, "Password is required", "MISSING_PASSWORD")
  end

  defp legacy_error(conn, :missing_name, _opts) do
    json_error(conn, 400, "Name is required", "MISSING_NAME")
  end

  defp legacy_error(conn, :password_too_short, _opts) do
    json_error(conn, 400, "Password must be at least 8 characters long", "PASSWORD_TOO_SHORT")
  end

  defp legacy_error(conn, reason, opts) do
    if Keyword.get(opts, :simple?, false) do
      conn
      |> put_cors_headers()
      |> put_status(Sso.status(reason))
      |> json(%{error: Sso.error_message(reason)})
    else
      json_error(conn, Sso.status(reason), Sso.error_message(reason), Sso.error_code(reason))
    end
  end

  defp legacy_error(conn, reason), do: legacy_error(conn, reason, [])

  defp json_error(conn, status, message, code) do
    conn
    |> put_cors_headers()
    |> put_status(status)
    |> json(%{success: false, error: message, code: code})
  end

  defp put_cors_headers(conn) do
    origin = get_req_header(conn, "origin") |> List.first()

    conn
    |> put_resp_header("access-control-allow-origin", origin || "*")
    |> put_resp_header("access-control-allow-methods", "GET, POST, PUT, DELETE, OPTIONS")
    |> put_resp_header("access-control-allow-headers", "Content-Type, Authorization")
  end
end
