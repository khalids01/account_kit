defmodule Accountkit.Accounts.Checks.PlatformOwner do
  @moduledoc """
  Ash policy check for global AccountKit platform owners.
  """
  use Ash.Policy.SimpleCheck

  alias Accountkit.Accounts.PlatformRole

  @impl true
  def describe(_opts), do: "actor is a platform owner"

  @impl true
  def match?(nil, _context, _opts), do: false

  def match?(%{id: user_id}, _context, _opts) when not is_nil(user_id) do
    PlatformRole
    |> Ash.Query.for_read(:get_by_user_and_role, %{user_id: user_id, role: :platform_owner},
      authorize?: false
    )
    |> Ash.exists?()
  end

  def match?(_actor, _context, _opts), do: false
end
