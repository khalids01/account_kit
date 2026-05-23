defmodule AccountkitWeb.Dashboard.OrganizationsLive do
  use AccountkitWeb, :live_view

  alias Accountkit.Accounts.{Authorization, Organization, OrganizationMembership}
  alias AccountkitWeb.Components.DashboardLayout

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    if Authorization.platform_owner?(user) do
      {:ok,
       socket
       |> assign(:page_title, "Organizations")
       |> assign(:current_scope, %{user: user})
       |> assign(:dashboard_context, DashboardLayout.dashboard_context(user))
       |> assign(:sidebar_collapsed?, false)
       |> load_data(user)}
    else
      {:ok, push_navigate(socket, to: ~p"/dashboard")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <DashboardLayout.dashboard_layout
      flash={@flash}
      current_scope={@current_scope}
      dashboard_context={@dashboard_context}
      sidebar_collapsed?={@sidebar_collapsed?}
      page_title={@page_title}
      active_nav={:organizations}
    >
      <.tabs id="organizations-tabs" variant="pills" color="primary" padding="small">
        <:tab active>Organizations</:tab>
        <:tab>Owners</:tab>

        <:panel>
          <.organizations_table organizations={@organizations} />
          <.organizations_cards organizations={@organizations} />
        </:panel>

        <:panel>
          <.owners_table memberships={@org_admin_memberships} />
          <.owners_cards memberships={@org_admin_memberships} />
        </:panel>
      </.tabs>
    </DashboardLayout.dashboard_layout>
    """
  end

  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_collapsed?, &(!&1))}
  end

  attr :organizations, :list, required: true

  defp organizations_table(assigns) do
    ~H"""
    <div class="hidden overflow-hidden rounded-2xl border border-base-300 bg-base-100 shadow-sm md:block">
      <table class="w-full text-left text-sm">
        <thead class="border-b border-base-300 bg-base-200/50 text-xs uppercase tracking-wide text-base-content/60">
          <tr>
            <th class="px-4 py-3 font-medium">Name</th>
            <th class="px-4 py-3 font-medium">Owner</th>
            <th class="px-4 py-3 font-medium">End users</th>
            <th class="px-4 py-3 font-medium">Created</th>
            <th class="px-4 py-3 font-medium"><span class="sr-only">Actions</span></th>
          </tr>
        </thead>
        <tbody class="divide-y divide-base-300">
          <tr :for={org <- @organizations} id={"organization-#{org.id}"}>
            <td class="px-4 py-3 font-medium">{org.name}</td>
            <td class="px-4 py-3 text-base-content/70">{org_admin_label(org)}</td>
            <td class="px-4 py-3 text-base-content/70">{org.end_users_count}</td>
            <td class="px-4 py-3 text-base-content/70">{format_datetime(org.created_at)}</td>
            <td class="px-4 py-3 text-right">
              <.org_actions_menu id={"org-actions-#{org.id}"} />
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  attr :organizations, :list, required: true

  defp organizations_cards(assigns) do
    ~H"""
    <div class="space-y-3 md:hidden">
      <article
        :for={org <- @organizations}
        id={"organization-card-#{org.id}"}
        class="rounded-2xl border border-base-300 bg-base-100 p-4 shadow-sm"
      >
        <div class="flex items-start justify-between gap-3">
          <div class="min-w-0">
            <h3 class="truncate font-semibold">{org.name}</h3>
            <p class="mt-1 text-sm text-base-content/70">Owner: {org_admin_label(org)}</p>
          </div>
          <.org_actions_menu id={"org-actions-mobile-#{org.id}"} />
        </div>
        <dl class="mt-4 grid grid-cols-2 gap-3 text-sm">
          <div>
            <dt class="text-xs uppercase tracking-wide text-base-content/50">End users</dt>
            <dd class="mt-1 font-medium">{org.end_users_count}</dd>
          </div>
          <div>
            <dt class="text-xs uppercase tracking-wide text-base-content/50">Created</dt>
            <dd class="mt-1 font-medium">{format_datetime(org.created_at)}</dd>
          </div>
        </dl>
      </article>
    </div>
    """
  end

  attr :memberships, :list, required: true

  defp owners_table(assigns) do
    ~H"""
    <div class="hidden overflow-hidden rounded-2xl border border-base-300 bg-base-100 shadow-sm md:block">
      <table class="w-full text-left text-sm">
        <thead class="border-b border-base-300 bg-base-200/50 text-xs uppercase tracking-wide text-base-content/60">
          <tr>
            <th class="px-4 py-3 font-medium">Name</th>
            <th class="px-4 py-3 font-medium">Email</th>
            <th class="px-4 py-3 font-medium">Organization</th>
            <th class="px-4 py-3 font-medium">Created</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-base-300">
          <tr :for={membership <- @memberships} id={"owner-#{membership.id}"}>
            <td class="px-4 py-3 font-medium">{owner_name(membership)}</td>
            <td class="px-4 py-3 text-base-content/70">{owner_email(membership)}</td>
            <td class="px-4 py-3 text-base-content/70">{membership.organization.name}</td>
            <td class="px-4 py-3 text-base-content/70">{format_datetime(membership.created_at)}</td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  attr :memberships, :list, required: true

  defp owners_cards(assigns) do
    ~H"""
    <div class="space-y-3 md:hidden">
      <article
        :for={membership <- @memberships}
        id={"owner-card-#{membership.id}"}
        class="rounded-2xl border border-base-300 bg-base-100 p-4 shadow-sm"
      >
        <h3 class="font-semibold">{owner_name(membership)}</h3>
        <p class="mt-1 truncate text-sm text-base-content/70">{owner_email(membership)}</p>
        <dl class="mt-4 space-y-3 text-sm">
          <div>
            <dt class="text-xs uppercase tracking-wide text-base-content/50">Organization</dt>
            <dd class="mt-1 font-medium">{membership.organization.name}</dd>
          </div>
          <div>
            <dt class="text-xs uppercase tracking-wide text-base-content/50">Created</dt>
            <dd class="mt-1 font-medium">{format_datetime(membership.created_at)}</dd>
          </div>
        </dl>
      </article>
    </div>
    """
  end

  attr :id, :string, required: true

  defp org_actions_menu(assigns) do
    ~H"""
    <.dropdown id={@id} relative="relative" position="bottom" width="w-40">
      <:trigger>
        <button
          type="button"
          class="inline-flex size-9 items-center justify-center rounded-lg border border-base-300 hover:bg-base-200"
          aria-label="Organization actions"
        >
          <.icon name="hero-ellipsis-horizontal" class="size-5" />
        </button>
      </:trigger>
      <.dropdown_content padding="extra_small" rounded="large">
        <.list size="small">
          <:item icon="hero-eye">View</:item>
          <:item icon="hero-pencil-square">Edit</:item>
          <:item icon="hero-no-symbol">Suspend</:item>
        </.list>
      </.dropdown_content>
    </.dropdown>
    """
  end

  defp load_data(socket, user) do
    organizations =
      Organization
      |> Ash.Query.for_read(:list_for_platform, %{}, actor: user)
      |> Ash.Query.load([:end_users_count, memberships: :user])
      |> Ash.read!()

    org_admin_memberships =
      OrganizationMembership
      |> Ash.Query.for_read(:list_org_admins_for_platform, %{}, actor: user)
      |> Ash.Query.load([:user, :organization])
      |> Ash.read!()

    socket
    |> assign(:organizations, organizations)
    |> assign(:org_admin_memberships, org_admin_memberships)
  end

  defp org_admin_label(%{memberships: memberships}) when is_list(memberships) do
    memberships
    |> Enum.find(&(&1.role == :org_admin))
    |> case do
      %{user: user} -> owner_display_name(user)
      _ -> "—"
    end
  end

  defp org_admin_label(_), do: "—"

  defp owner_name(%{user: user}), do: owner_display_name(user)
  defp owner_name(_), do: "—"

  defp owner_email(%{user: %{email: email}}) when not is_nil(email), do: to_string(email)
  defp owner_email(_), do: "—"

  defp owner_display_name(%{name: name}) when is_binary(name) and name != "", do: name

  defp owner_display_name(%{email: email}) when not is_nil(email), do: to_string(email)
  defp owner_display_name(_), do: "—"

  defp format_datetime(nil), do: "—"

  defp format_datetime(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%b %-d, %Y")
  end
end
