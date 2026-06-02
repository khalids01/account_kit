defmodule AccountkitWeb.Features.EndUsers.Queries do
  alias Accountkit.Accounts.{Authorization, EndUser, Organization, SsoApplication}
  alias AccountkitWeb.Features.EndUsers.Pagination

  require Ash.Query

  def list(actor, filters) do
    rows =
      actor
      |> scoped_end_users()
      |> filter_archived(filters["tab"])
      |> filter_organization(filters["organization_id"])
      |> filter_status(filters["status"])
      |> filter_auth_methods(filters["auth_methods"])
      |> filter_search(filters["search"])
      |> sort_rows(filters["sort"])

    page =
      filters["page"]
      |> to_string()
      |> String.to_integer()

    Pagination.paginate(rows, page)
  end

  def organizations_for(actor) do
    if Authorization.platform_owner?(actor) do
      Organization
      |> Ash.Query.for_read(:read, %{}, authorize?: false)
      |> Ash.Query.sort(name: :asc)
      |> Ash.read!()
    else
      ids = Authorization.org_admin_organization_ids(actor)

      Organization
      |> Ash.Query.for_read(:read, %{}, authorize?: false)
      |> Ash.Query.filter(id in ^ids)
      |> Ash.Query.sort(name: :asc)
      |> Ash.read!()
    end
  end

  def platform_owner?(actor), do: Authorization.platform_owner?(actor)

  def get_scoped(id, actor) do
    scoped_end_users(actor)
    |> Enum.find(&(&1.id == id))
    |> case do
      nil -> {:error, :not_found}
      row -> {:ok, row.end_user}
    end
  end

  def scoped_end_users(actor) do
    allowed_application_ids = scoped_application_ids(actor)

    EndUser
    |> Ash.Query.for_read(:read, %{}, actor: actor)
    |> Ash.Query.filter(sso_application_id in ^allowed_application_ids)
    |> Ash.Query.load(sso_application: [:organization])
    |> Ash.read!()
    |> Enum.map(&row/1)
  end

  defp scoped_application_ids(actor) do
    query =
      if Authorization.platform_owner?(actor) do
        SsoApplication
        |> Ash.Query.for_read(:list_for_platform, %{}, authorize?: false)
      else
        organization_ids = Authorization.org_admin_organization_ids(actor)

        SsoApplication
        |> Ash.Query.for_read(:read, %{}, authorize?: false)
        |> Ash.Query.filter(organization_id in ^organization_ids)
      end

    query
    |> Ash.read!()
    |> Enum.map(& &1.id)
  end

  defp row(%EndUser{} = end_user) do
    application = end_user.sso_application
    organization = application.organization

    %{
      id: end_user.id,
      end_user: end_user,
      name: end_user.name,
      email: to_string(end_user.email),
      phone: end_user.phone,
      auth_methods: end_user.auth_methods || [],
      status: status(end_user),
      banned?: match?(%DateTime{}, end_user.banned_at),
      archived?: match?(%DateTime{}, end_user.archived_at),
      created_at: end_user.created_at,
      application: application,
      organization: organization
    }
  end

  defp filter_archived(rows, "archived"), do: Enum.filter(rows, & &1.archived?)
  defp filter_archived(rows, _tab), do: Enum.reject(rows, & &1.archived?)

  defp filter_organization(rows, organization_id) when organization_id in [nil, "all"], do: rows

  defp filter_organization(rows, organization_id) do
    Enum.filter(rows, &(&1.organization.id == organization_id))
  end

  defp filter_status(rows, "active"), do: Enum.filter(rows, &(&1.status == :active))
  defp filter_status(rows, "banned"), do: Enum.filter(rows, &(&1.status == :banned))
  defp filter_status(rows, _status), do: rows

  defp filter_auth_methods(rows, []), do: rows

  defp filter_auth_methods(rows, auth_methods) do
    Enum.filter(rows, fn row ->
      Enum.any?(auth_methods, &(&1 in row.auth_methods))
    end)
  end

  defp filter_search(rows, search) when search in [nil, ""], do: rows

  defp filter_search(rows, search) do
    search = String.downcase(search)

    Enum.filter(rows, fn row ->
      [row.name, row.email, row.phone]
      |> Enum.reject(&is_nil/1)
      |> Enum.any?(&(String.downcase(to_string(&1)) =~ search))
    end)
  end

  defp sort_rows(rows, "oldest"), do: Enum.sort_by(rows, &sort_timestamp/1, :asc)
  defp sort_rows(rows, _sort), do: Enum.sort_by(rows, &sort_timestamp/1, :desc)

  defp sort_timestamp(%{created_at: %DateTime{} = datetime}),
    do: DateTime.to_unix(datetime, :microsecond)

  defp sort_timestamp(_row), do: 0

  defp status(%{archived_at: %DateTime{}}), do: :archived
  defp status(%{banned_at: %DateTime{}}), do: :banned
  defp status(_end_user), do: :active
end
