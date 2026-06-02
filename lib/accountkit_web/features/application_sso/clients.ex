defmodule AccountkitWeb.Features.ApplicationSso.Clients do
  @moduledoc """
  Legacy-compatible SSO client validation and callback helpers.
  """

  alias Accountkit.Accounts.SsoApplication

  require Ash.Query

  def validate_client(token, redirect_url, client_origin \\ nil) do
    with {:ok, application} <- get_application_by_token(token),
         :ok <- ensure_active(application),
         :ok <- validate_redirect_url(application, redirect_url),
         :ok <- validate_client_origin(application, client_origin) do
      {:ok, application}
    end
  end

  def get_application_by_token(token) when is_binary(token) and token != "" do
    SsoApplication
    |> Ash.Query.for_read(
      :get_by_client_token_hash,
      %{client_token_hash: SsoApplication.hash_token(token)},
      authorize?: false
    )
    |> Ash.read_one()
    |> case do
      {:ok, %SsoApplication{} = application} -> {:ok, application}
      {:ok, nil} -> {:error, :invalid_client}
      {:error, _error} -> {:error, :invalid_client}
    end
  end

  def get_application_by_token(_token), do: {:error, :missing_token}

  def ensure_active(%SsoApplication{archived_at: %DateTime{}}), do: {:error, :inactive_client}
  def ensure_active(%SsoApplication{deactivated_at: %DateTime{}}), do: {:error, :inactive_client}
  def ensure_active(%SsoApplication{}), do: :ok

  def validate_redirect_url(%SsoApplication{} = application, redirect_url)
      when is_binary(redirect_url) and redirect_url != "" do
    redirect_url = String.downcase(redirect_url)

    if Enum.any?(
         application.redirect_urls,
         &String.starts_with?(redirect_url, String.downcase(&1))
       ) do
      :ok
    else
      {:error, :invalid_redirect_url}
    end
  end

  def validate_redirect_url(_application, _redirect_url), do: {:error, :missing_redirect_url}

  def validate_client_origin(_application, origin) when origin in [nil, ""], do: :ok

  def validate_client_origin(%SsoApplication{} = application, origin) when is_binary(origin) do
    origin = String.downcase(origin)

    if Enum.any?(application.allowed_origins, &origin_allowed?(origin, &1)) do
      :ok
    else
      {:error, :invalid_origin}
    end
  end

  def public_client(%SsoApplication{} = application) do
    %{
      id: application.id,
      name: application.name,
      logoUrl: application.logo_url,
      passwordEnabled: application.password_enabled,
      magicLinkEnabled: application.magic_link_enabled,
      googleEnabled: application.google_enabled,
      googleClientId: application.google_client_id,
      facebookEnabled: application.facebook_enabled,
      facebookAppId: application.facebook_app_id,
      linkedinEnabled: application.linkedin_enabled,
      linkedinClientId: application.linkedin_client_id
    }
  end

  def callback_url(redirect_url, callback_params, auth_token) do
    expires_in = token_expires_in(auth_token)

    redirect_url
    |> URI.parse()
    |> merge_query(callback_params, auth_token, expires_in)
    |> URI.to_string()
  end

  def token_expires_in(token) when is_binary(token) do
    with {:ok, %{"exp" => exp}} when is_integer(exp) <- Joken.peek_claims(token) do
      now = DateTime.utc_now() |> DateTime.to_unix()

      max(exp - now, 0)
    else
      _error -> 0
    end
  end

  def token_expires_in(_token), do: 0

  def error_message(:missing_token), do: "Client token is required"
  def error_message(:missing_redirect_url), do: "Redirect URL is required"
  def error_message(:invalid_client), do: "Invalid client token"
  def error_message(:inactive_client), do: "Invalid client token"
  def error_message(:invalid_redirect_url), do: "Invalid redirect URL"
  def error_message(:invalid_origin), do: "Invalid request origin"
  def error_message(:password_disabled), do: "Password authentication is disabled for this client"
  def error_message(:invalid_credentials), do: "Invalid email or password"
  def error_message(:email_exists), do: "Email already registered"
  def error_message(:invalid_token), do: "Invalid or expired token"
  def error_message(_reason), do: "An unexpected error occurred"

  def error_code(:missing_token), do: "MISSING_TOKEN"
  def error_code(:missing_redirect_url), do: "MISSING_REDIRECT_URL"
  def error_code(:invalid_client), do: "INVALID_CLIENT"
  def error_code(:inactive_client), do: "INVALID_CLIENT"
  def error_code(:invalid_redirect_url), do: "INVALID_REDIRECT_URL"
  def error_code(:invalid_origin), do: "INVALID_ORIGIN"
  def error_code(:password_disabled), do: "PASSWORD_DISABLED"
  def error_code(:invalid_credentials), do: "INVALID_CREDENTIALS"
  def error_code(:email_exists), do: "EMAIL_ALREADY_EXISTS"
  def error_code(:invalid_token), do: "INVALID_TOKEN"
  def error_code(_reason), do: "SERVER_ERROR"

  def status(:missing_token), do: 400
  def status(:missing_redirect_url), do: 400
  def status(:invalid_client), do: 401
  def status(:inactive_client), do: 401
  def status(:invalid_redirect_url), do: 400
  def status(:invalid_origin), do: 403
  def status(:password_disabled), do: 400
  def status(:invalid_credentials), do: 401
  def status(:email_exists), do: 400
  def status(:invalid_token), do: 401
  def status(_reason), do: 500

  defp origin_allowed?(origin, allowed_origin) when is_binary(allowed_origin) do
    allowed_origin = String.downcase(allowed_origin)

    cond do
      allowed_origin == origin ->
        true

      String.starts_with?(allowed_origin, "*.") ->
        suffix = String.replace_prefix(allowed_origin, "*", "")
        String.ends_with?(origin, suffix)

      true ->
        false
    end
  end

  defp origin_allowed?(_origin, _allowed_origin), do: false

  defp merge_query(%URI{} = uri, callback_params, auth_token, expires_in) do
    query =
      uri.query
      |> decode_query()
      |> Map.merge(decode_callback_params(callback_params))
      |> Map.put("auth_token", auth_token)
      |> Map.put("expires_in", expires_in)

    %{uri | query: URI.encode_query(query)}
  end

  defp decode_query(nil), do: %{}
  defp decode_query(""), do: %{}
  defp decode_query(query), do: URI.decode_query(query)

  defp decode_callback_params(value) when value in [nil, ""], do: %{}

  defp decode_callback_params(value) when is_map(value) do
    value
    |> Enum.reject(fn {key, _value} -> key in [:auth_token, "auth_token"] end)
    |> Map.new(fn {key, value} -> {to_string(key), to_string(value)} end)
  end

  defp decode_callback_params(value) when is_binary(value) do
    case Jason.decode(value) do
      {:ok, decoded} when is_map(decoded) ->
        decode_callback_params(decoded)

      _error ->
        value
        |> URI.decode_query()
        |> decode_callback_params()
    end
  end

  defp decode_callback_params(_value), do: %{}
end
