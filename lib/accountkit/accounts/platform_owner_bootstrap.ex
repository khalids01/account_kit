defmodule Accountkit.Accounts.PlatformOwnerBootstrap do
  @moduledoc """
  Grants the initial platform owner role from explicit configuration.

  This intentionally never promotes the first registered user. Operators must
  provide a configured email and create/sign in that user through normal auth.
  """

  require Logger

  alias Accountkit.Auth.Email
  alias Accountkit.Accounts.{PlatformRole, User}

  def run do
    configured_email()
    |> grant()
    |> log_result()
  end

  def grant(nil), do: {:error, :missing_email}
  def grant(""), do: {:error, :missing_email}

  def grant(email) when is_binary(email) do
    email = Email.normalize(email)

    if email == "" do
      {:error, :missing_email}
    else
      case get_user(email) do
        {:ok, %User{} = user} -> grant_user(user)
        {:ok, nil} -> {:error, :user_not_found}
        {:error, error} -> {:error, error}
      end
    end
  end

  def grant_if_configured_user(%User{email: email} = user) do
    configured_email = configured_email()

    if configured_email && Email.normalize(email) == configured_email do
      grant_user(user)
    else
      {:ok, :not_configured_owner}
    end
  end

  def grant_if_configured_user(_user), do: {:ok, :not_configured_owner}

  defp grant_user(%User{id: user_id}) do
    if platform_owner_exists?(user_id) do
      {:ok, :already_exists}
    else
      case create_platform_owner_role(user_id) do
        {:ok, %PlatformRole{}} -> {:ok, :created}
        {:error, error} -> {:error, error}
      end
    end
  end

  defp get_user(email) do
    User
    |> Ash.Query.for_read(:get_by_email, %{email: email}, authorize?: false)
    |> Ash.read_one()
  end

  defp platform_owner_exists?(user_id) do
    PlatformRole
    |> Ash.Query.for_read(:get_by_user_and_role, %{user_id: user_id, role: :platform_owner},
      authorize?: false
    )
    |> Ash.exists?()
  end

  defp create_platform_owner_role(user_id) do
    PlatformRole
    |> Ash.Changeset.for_create(:create, %{user_id: user_id, role: :platform_owner})
    |> Ash.create(authorize?: false)
  end

  defp normalize_configured_email(nil), do: nil
  defp normalize_configured_email(""), do: nil

  defp normalize_configured_email(email) when is_binary(email) do
    normalized_email = Email.normalize(email)
    if normalized_email == "", do: nil, else: normalized_email
  end

  defp configured_email do
    :accountkit
    |> Application.get_env(:platform_owner_email)
    |> Kernel.||(System.get_env("ACCOUNTKIT_PLATFORM_OWNER_EMAIL"))
    |> Kernel.||(read_env_file_value("ACCOUNTKIT_PLATFORM_OWNER_EMAIL"))
    |> normalize_configured_email()
  end

  defp read_env_file_value(key) do
    env_path = Path.expand("../../../.env", __DIR__)

    if File.exists?(env_path) do
      env_path
      |> File.stream!()
      |> Stream.map(&String.trim/1)
      |> Stream.reject(&(&1 == "" or String.starts_with?(&1, "#")))
      |> Enum.find_value(fn line ->
        case String.split(line, "=", parts: 2) do
          [^key, value] -> value |> String.trim() |> String.trim_leading("\"") |> String.trim_trailing("\"")
          _ -> nil
        end
      end)
    end
  end

  defp log_result({:ok, :created} = result) do
    Logger.info("Granted configured platform_owner role.")
    result
  end

  defp log_result({:ok, :already_exists} = result) do
    Logger.info("Configured platform_owner role already exists.")
    result
  end

  defp log_result({:error, :missing_email} = result) do
    Logger.info("Skipping platform_owner bootstrap: ACCOUNTKIT_PLATFORM_OWNER_EMAIL is not set.")
    result
  end

  defp log_result({:error, :user_not_found} = result) do
    Logger.warning("Skipping platform_owner bootstrap: configured user email was not found.")
    result
  end

  defp log_result({:error, error} = result) do
    Logger.error("Skipping platform_owner bootstrap: #{inspect(error)}")
    result
  end
end
