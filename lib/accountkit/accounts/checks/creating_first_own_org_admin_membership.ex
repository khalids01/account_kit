defmodule Accountkit.Accounts.Checks.CreatingFirstOwnOrgAdminMembership do
  @moduledoc """
  Allows onboarding users to attach themselves as the first org admin.
  """
  use Ash.Policy.SimpleCheck

  alias Accountkit.Accounts.OrganizationMembership

  @impl true
  def describe(_opts), do: "actor is creating the first org_admin membership for themselves"

  @impl true
  def match?(nil, _context, _opts), do: false

  def match?(%{id: user_id}, %{changeset: %Ash.Changeset{} = changeset}, _opts)
      when not is_nil(user_id) do
    membership_user_id = Ash.Changeset.get_attribute(changeset, :user_id)
    organization_id = Ash.Changeset.get_attribute(changeset, :organization_id)
    role = Ash.Changeset.get_attribute(changeset, :role)

    membership_user_id == user_id and role == :org_admin and not is_nil(organization_id) and
      not organization_has_memberships?(organization_id)
  end

  def match?(_actor, _context, _opts), do: false

  defp organization_has_memberships?(organization_id) do
    OrganizationMembership
    |> Ash.Query.for_read(:for_organization, %{organization_id: organization_id}, authorize?: false)
    |> Ash.exists?()
  end
end
