defmodule Accountkit.Accounts.PlatformOwnerBootstrap do
  @moduledoc """
  Grants the initial platform owner role from explicit configuration.

  This intentionally never promotes the first registered user. Operators must
  provide a configured email and create/sign in that user through normal auth.
  """

  require Logger

  alias Accountkit.Accounts.{PlatformRole, User}

  def run do
    :accountkit
    |> Application.get_env(:platform_owner_email)
    |> grant()
    |> log_result()
  end

  def grant(nil), do: {:error, :missing_email}
  def grant(""), do: {:error, :missing_email}

  def grant(email) when is_binary(email) do
    email = String.trim(email)

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
