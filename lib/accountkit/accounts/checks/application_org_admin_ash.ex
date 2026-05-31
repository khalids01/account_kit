defmodule Accountkit.Accounts.Checks.ApplicationOrgAdmin do
  @moduledoc """
  Allows org admins to manage applications for their own organization.
  """
  use Ash.Policy.SimpleCheck

  alias Accountkit.Accounts.Authorization

  @impl true
  def describe(_opts), do: "actor is an org admin for the application organization"

  @impl true
  def match?(nil, _context, _opts), do: false

  def match?(%{id: user_id} = actor, %{changeset: %Ash.Changeset{} = changeset}, _opts)
      when not is_nil(user_id) do
    changeset
    |> Ash.Changeset.get_attribute(:organization_id)
    |> then(&Authorization.org_admin?(actor, &1))
  end

  def match?(_actor, _context, _opts), do: false
end
