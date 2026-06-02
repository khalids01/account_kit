defmodule Accountkit.Accounts.Authorization do
  @moduledoc """
  Server-side authorization helpers for AccountKit control-plane access.

  These helpers intentionally check scoped role assignment resources instead of
  relying on a global role field on the user.
  """

  alias Accountkit.Accounts.{OrganizationMembership, PlatformRole, User}

  def platform_owner?(%{id: user_id}) when not is_nil(user_id) do
    PlatformRole
    |> Ash.Query.for_read(:get_by_user_and_role, %{user_id: user_id, role: :platform_owner},
      authorize?: false
    )
    |> Ash.exists?()
  end

  def platform_owner?(_user), do: false

  def org_admin?(%{id: user_id}, organization_id)
      when not is_nil(user_id) and not is_nil(organization_id) do
    OrganizationMembership
    |> Ash.Query.for_read(
      :get_by_user_org_and_role,
      %{user_id: user_id, organization_id: organization_id, role: :org_admin},
      authorize?: false
    )
    |> Ash.exists?()
  end

  def org_admin?(_user, _organization_id), do: false

  def dashboard_user?(%{id: user_id} = user) when not is_nil(user_id) do
    platform_owner?(user) or org_membership_exists?(user_id)
  end

  def dashboard_user?(_user), do: false

  def banned?(%{id: user_id}) when not is_nil(user_id) do
    User
    |> Ash.Query.for_read(:get_by_id, %{id: user_id}, authorize?: false)
    |> Ash.read_one()
    |> case do
      {:ok, %{banned_at: %DateTime{}}} -> true
      _ -> false
    end
  end

  def banned?(_user), do: false

  def onboarding_required?(%{id: user_id} = user) when not is_nil(user_id) do
    not dashboard_user?(user)
  end

  def onboarding_required?(_user), do: false

  def first_org_membership(%{id: user_id}) when not is_nil(user_id) do
    OrganizationMembership
    |> Ash.Query.for_read(:for_user, %{user_id: user_id}, authorize?: false)
    |> Ash.Query.load(:organization)
    |> Ash.read!()
    |> List.first()
  end

  def first_org_membership(_user), do: nil

  def org_admin_organization_ids(%{id: user_id}) when not is_nil(user_id) do
    OrganizationMembership
    |> Ash.Query.for_read(:for_user, %{user_id: user_id}, authorize?: false)
    |> Ash.read!()
    |> Enum.filter(&(&1.role == :org_admin))
    |> Enum.map(& &1.organization_id)
  end

  def org_admin_organization_ids(_user), do: []

  defp org_membership_exists?(user_id) do
    OrganizationMembership
    |> Ash.Query.for_read(:for_user, %{user_id: user_id}, authorize?: false)
    |> Ash.exists?()
  end
end
