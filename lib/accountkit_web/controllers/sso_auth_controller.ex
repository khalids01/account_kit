defmodule AccountkitWeb.SsoAuthController do
  use AccountkitWeb, :controller

  import Ecto.Query

  alias Accountkit.Accounts.{EndUser, EndUserToken}
  alias Accountkit.Repo
  alias AccountkitWeb.Features.ApplicationSso.{Auth, Clients}

  def options(conn, _params) do
    conn
    |> put_cors_headers()
    |> send_resp(204, "")
  end

  def validate_client(conn, params) do
    with {:ok, _application} <-
           Clients.validate_client(params["token"], params["redirectUrl"], params["clientOrigin"]) do
      conn
      |> put_cors_headers()
      |> json(%{success: true})
    else
      {:error, reason} -> legacy_error(conn, reason, simple?: true)
    end
  end

  def client_info(conn, %{"token" => token}) do
    with {:ok, application} <- Clients.get_application_by_token(token),
         :ok <- Clients.ensure_active(application) do
      conn
      |> put_cors_headers()
      |> json(Clients.public_client(application))
    else
      {:error, reason} -> legacy_error(conn, reason, simple?: true)
    end
  end

  def client_info(conn, _params), do: legacy_error(conn, :missing_token, simple?: true)

  def login(conn, params) do
    with :ok <- require_param(params, "email", :missing_email),
         :ok <- require_param(params, "password", :missing_password),
         {:ok, application} <- validate_password_client(params),
         {:ok, end_user} <- Auth.sign_in(application, params) do
      auth_success(conn, end_user, application)
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
         {:ok, end_user} <- Auth.register(application, params) do
      auth_success(conn, end_user, application)
    else
      {:error, reason} -> legacy_error(conn, reason)
    end
  end

  def user(conn, _params) do
    case conn.assigns[:current_end_user] do
      %EndUser{} = end_user ->
        conn
        |> put_cors_headers()
        |> json(%{success: true, user: Auth.user_json(end_user)})

      _user ->
        legacy_error(conn, :invalid_token)
    end
  end

  def me(conn, params), do: user(conn, params)

  def logout(conn, _params) do
    with %EndUser{} <- conn.assigns[:current_end_user],
         %EndUserToken{jti: jti} <- conn.assigns[:current_end_user_token_record],
         {count, _} when count > 0 <- delete_token(jti) do
      conn
      |> put_cors_headers()
      |> json(%{success: true})
    else
      _error -> legacy_error(conn, :invalid_token)
    end
  end

  defp validate_password_client(params) do
    with {:ok, application} <- Clients.validate_client(params["token"], params["redirectUrl"]) do
      if application.password_enabled do
        {:ok, application}
      else
        {:error, :password_disabled}
      end
    end
  end

  defp auth_success(conn, end_user, application) do
    token = end_user.__metadata__.token

    conn
    |> put_cors_headers()
    |> json(%{
      success: true,
      token: token,
      expires_in: Clients.token_expires_in(token),
      user: Auth.user_json(end_user),
      client: Auth.client_json(application)
    })
  end

  defp delete_token(jti) do
    Repo.delete_all(
      from token in "end_user_tokens",
        where: token.jti == ^jti
    )
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

  defp legacy_error(conn, :invalid_email, _opts) do
    json_error(conn, 400, "Enter a valid email address.", "INVALID_EMAIL")
  end

  defp legacy_error(conn, reason, opts) do
    if Keyword.get(opts, :simple?, false) do
      conn
      |> put_cors_headers()
      |> put_status(Clients.status(reason))
      |> json(%{error: Clients.error_message(reason)})
    else
      json_error(
        conn,
        Clients.status(reason),
        Clients.error_message(reason),
        Clients.error_code(reason)
      )
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
