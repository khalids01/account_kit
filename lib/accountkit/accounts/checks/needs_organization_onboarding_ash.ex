defmodule Accountkit.Accounts.Checks.NeedsOrganizationOnboarding do
  @moduledoc """
  Allows organization creation only for signed-in users without scoped dashboard access.
  """
  use Ash.Policy.SimpleCheck

  alias Accountkit.Accounts.Authorization

  @impl true
  def describe(_opts), do: "actor needs organization onboarding"

  @impl true
  def match?(nil, _context, _opts), do: false

  def match?(actor, _context, _opts) do
    Authorization.onboarding_required?(actor)
  end
end
