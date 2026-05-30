defmodule AccountkitWeb.Features.Users.Queries do
  alias Accountkit.Accounts.{OrganizationMembership, PlatformRole}

  def dashboard_users_for_platform(user, opts \\ []) do
    archived? = Keyword.get(opts, :archived?, false)
    platform_roles = platform_roles_for_platform(user)
    org_admin_memberships = org_admin_memberships_for_platform(user)

    platform_rows =
      platform_roles
      |> Enum.map(&platform_role_row/1)

    org_admin_rows =
      org_admin_memberships
      |> Enum.map(&org_admin_row/1)

    (platform_rows ++ org_admin_rows)
    |> Enum.group_by(& &1.user.id)
    |> Enum.map(fn {_user_id, rows} -> merge_rows(rows) end)
    |> Enum.filter(&(archived? == archived?(&1)))
    |> Enum.sort_by(&String.downcase(to_string(&1.email)))
  end

  defp platform_roles_for_platform(user) do
    PlatformRole
    |> Ash.Query.for_read(:read, %{}, actor: user)
    |> Ash.Query.load(:user)
    |> Ash.read!()
  end

  defp org_admin_memberships_for_platform(user) do
    OrganizationMembership
    |> Ash.Query.for_read(:list_org_admins_for_platform, %{}, actor: user)
    |> Ash.Query.load([:user, :organization])
    |> Ash.read!()
  end

  defp platform_role_row(%{user: user, created_at: created_at}) do
    %{
      user: user,
      name: display_name(user),
      email: user_email(user),
      role: :platform_owner,
      organizations: [],
      created_at: created_at,
      banned_at: user.banned_at,
      archived_at: user.archived_at
    }
  end

  defp org_admin_row(%{user: user, organization: organization, created_at: created_at}) do
    %{
      user: user,
      name: display_name(user),
      email: user_email(user),
      role: :org_admin,
      organizations: [organization],
      created_at: created_at,
      banned_at: user.banned_at,
      archived_at: user.archived_at
    }
  end

  defp merge_rows(rows) do
    platform_row = Enum.find(rows, &(&1.role == :platform_owner))
    base_row = platform_row || List.first(rows)

    organizations =
      rows
      |> Enum.flat_map(& &1.organizations)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq_by(& &1.id)
      |> Enum.sort_by(&String.downcase(&1.name))

    %{
      base_row
      | role: if(platform_row, do: :platform_owner, else: :org_admin),
        organizations: organizations,
        created_at: base_row.created_at,
        banned_at: base_row.banned_at,
        archived_at: base_row.archived_at
    }
  end

  defp archived?(%{archived_at: %DateTime{}}), do: true
  defp archived?(_row), do: false

  defp display_name(%{name: name}) when is_binary(name) and name != "", do: name
  defp display_name(user), do: user_email(user)

  defp user_email(%{email: email}) when not is_nil(email), do: to_string(email)
  defp user_email(_), do: "—"
end
