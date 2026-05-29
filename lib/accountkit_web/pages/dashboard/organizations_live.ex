defmodule AccountkitWeb.Pages.Dashboard.OrganizationsLive do
  use AccountkitWeb, :live_view

  alias Accountkit.Accounts.Authorization
  alias AccountkitWeb.Components.Sections.DashboardShell, as: DashboardLayout
  alias AccountkitWeb.Features.Organizations.Components, as: OrganizationComponents
  alias AccountkitWeb.Features.Organizations.Queries

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
      <.tabs
        id="organizations-tabs"
        variant="nav_pills"
        color="base"
        padding="extra_small"
        rounded="large"
        gap="small"
        class="[&_.tab-nav-pills]:rounded-xl [&_.tab-nav-pills]:border [&_.tab-nav-pills]:border-base-300 [&_.tab-nav-pills]:bg-base-200/50 [&_.tab-nav-pills]:p-1 [&_.tab-trigger]:rounded-lg [&_.tab-trigger]:!p-2 [&_.tab-trigger]:text-base-content/70 [&_.tab-trigger.active-tab]:!bg-primary [&_.tab-trigger.active-tab]:!text-primary-content [&_.tab-trigger.active-tab]:shadow-sm dark:[&_.tab-trigger.active-tab]:!bg-primary dark:[&_.tab-trigger.active-tab]:!text-primary-content"
      >
        <:tab active>Organizations</:tab>
        <:tab>Owners</:tab>

        <:panel>
          <OrganizationComponents.organizations_table organizations={@organizations} />
          <OrganizationComponents.organizations_cards organizations={@organizations} />
        </:panel>

        <:panel>
          <OrganizationComponents.owners_table memberships={@org_admin_memberships} />
          <OrganizationComponents.owners_cards memberships={@org_admin_memberships} />
        </:panel>
      </.tabs>
    </DashboardLayout.dashboard_layout>
    """
  end

  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_collapsed?, &(!&1))}
  end

  defp load_data(socket, user) do
    %{organizations: organizations, org_admin_memberships: org_admin_memberships} =
      Queries.dashboard_data(user)

    assign(socket,
      organizations: organizations,
      org_admin_memberships: org_admin_memberships
    )
  end
end
