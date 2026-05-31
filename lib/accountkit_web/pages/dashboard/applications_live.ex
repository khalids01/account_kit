defmodule AccountkitWeb.Pages.Dashboard.ApplicationsLive do
  use AccountkitWeb, :live_view

  alias Accountkit.Accounts.{Authorization, Organization, OrganizationMembership, SsoApplication}
  alias AccountkitWeb.Components.Sections.DashboardShell, as: DashboardLayout
  alias AccountkitWeb.Features.Applications.{Components, Forms}

  require Ash.Query

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    platform_owner? = Authorization.platform_owner?(user)

    {:ok,
     socket
     |> assign(:page_title, "Applications")
     |> assign(:current_scope, %{user: user})
     |> assign(:dashboard_context, DashboardLayout.dashboard_context(user))
     |> assign(:sidebar_collapsed?, false)
     |> assign(:platform_owner?, platform_owner?)
     |> assign(:selected_organization_id, "all")
     |> assign(:modal_mode, nil)
     |> assign(:editing_application, nil)
     |> assign(:viewing_application, nil)
     |> assign(:deactivating_application, nil)
     |> assign(:revealed_tokens, %{})
     |> load_organizations(user, platform_owner?)
     |> assign_forms()
     |> load_applications(user)}
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
      active_nav={:applications}
    >
      <section class="space-y-4">
        <div class="flex flex-col gap-3 px-1 sm:flex-row sm:items-end sm:justify-between sm:px-0">
          <div>
            <p class="text-sm font-semibold text-primary">SSO</p>
            <h2 class="text-2xl font-semibold tracking-normal">Applications</h2>
            <p class="max-w-2xl text-sm text-base-content/70">
              Client apps that can use AccountKit SSO.
            </p>
          </div>

          <div class="flex flex-col gap-2 sm:flex-row sm:items-end">
            <form :if={@platform_owner?} phx-change="filter_organization" class="sm:w-72">
              <label class="text-sm font-medium">Organization</label>
              <select
                name="organization_id"
                class="select select-bordered mt-2 w-full"
                value={@selected_organization_id}
              >
                <option value="all">All organizations</option>
                <option :for={organization <- @organizations} value={organization.id}>
                  {organization.name}
                </option>
              </select>
            </form>

            <button type="button" phx-click="new_application" class="btn btn-primary">
              Create
            </button>
          </div>
        </div>

        <Components.applications_grid applications={@applications} />

        <Components.application_form_modal
          :if={@modal_mode in [:create, :edit]}
          form={if @modal_mode == :create, do: @create_form, else: @edit_form}
          event={if @modal_mode == :create, do: "create_application", else: "update_application"}
          organizations={@organizations}
          platform_owner?={@platform_owner? and @modal_mode == :create}
          title={if @modal_mode == :create, do: "Create application", else: "Edit application"}
          submit_label={if @modal_mode == :create, do: "Create application", else: "Save changes"}
        />

        <Components.application_details_modal
          :if={@modal_mode == :view and @viewing_application}
          application={@viewing_application}
          token={Map.get(@revealed_tokens, @viewing_application.id)}
        />

        <Components.deactivate_confirmation_modal
          :if={@modal_mode == :confirm_deactivate and @deactivating_application}
          application={@deactivating_application}
        />
      </section>
    </DashboardLayout.dashboard_layout>
    """
  end

  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_collapsed?, &(!&1))}
  end

  def handle_event("filter_organization", %{"organization_id" => organization_id}, socket) do
    {:noreply,
     socket
     |> assign(:selected_organization_id, organization_id)
     |> load_applications(socket.assigns.current_user)}
  end

  def handle_event("new_application", _params, socket) do
    data = Forms.new_data()

    {:noreply,
     socket
     |> assign(:modal_mode, :create)
     |> assign(:create_form_data, data)
     |> assign(:create_form, Forms.form_for(data))
     |> assign(:editing_application, nil)
     |> assign(:viewing_application, nil)
     |> assign(:deactivating_application, nil)}
  end

  def handle_event("change_application_form", %{"application" => params}, socket) do
    {:noreply, update_active_form(socket, params)}
  end

  def handle_event("add_form_list_item", %{"field" => field}, socket) do
    {:noreply, update_active_form_list(socket, field, :add)}
  end

  def handle_event("remove_form_list_item", %{"field" => field, "index" => index}, socket) do
    {:noreply, update_active_form_list(socket, field, {:remove, String.to_integer(index)})}
  end

  def handle_event("create_application", %{"application" => params}, socket) do
    user = socket.assigns.current_user

    organization_id =
      socket.assigns.org_admin_organization && socket.assigns.org_admin_organization.id

    with {:ok, attrs} <-
           Forms.attrs_for_create(params, socket.assigns.platform_owner?, organization_id),
         {:ok, application} <-
           SsoApplication
           |> Ash.Changeset.for_create(:create, attrs, actor: user)
           |> Ash.create() do
      token = reveal_loaded_token(application, user)

      {:noreply,
       socket
       |> put_flash(:info, "Application created.")
       |> close_modal()
       |> reset_create_form()
       |> put_revealed_token(application.id, token)
       |> load_applications(user)}
    else
      _error ->
        {:noreply, put_flash(socket, :error, "Could not create application.")}
    end
  end

  def handle_event("edit_application", %{"id" => id}, socket) do
    user = socket.assigns.current_user

    case get_application(id, user) do
      {:ok, application} ->
        data = Forms.edit_data(application)

        {:noreply,
         socket
         |> assign(:modal_mode, :edit)
         |> assign(:editing_application, application)
         |> assign(:viewing_application, nil)
         |> assign(:deactivating_application, nil)
         |> assign(:edit_form_data, data)
         |> assign(:edit_form, Forms.form_for(data))}

      _error ->
        {:noreply, put_flash(socket, :error, "Could not load application.")}
    end
  end

  def handle_event("update_application", %{"application" => params}, socket) do
    user = socket.assigns.current_user
    application = socket.assigns.editing_application

    with attrs <- Forms.attrs_for_update(params),
         {:ok, _application} <-
           application
           |> Ash.Changeset.for_update(:update, attrs, actor: user)
           |> Ash.update() do
      {:noreply,
       socket
       |> put_flash(:info, "Application updated.")
       |> close_modal()
       |> load_applications(user)}
    else
      _error ->
        {:noreply, put_flash(socket, :error, "Could not update application.")}
    end
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, close_modal(socket)}
  end

  def handle_event("view_application", %{"id" => id}, socket) do
    user = socket.assigns.current_user

    case get_application(id, user) do
      {:ok, application} ->
        {:noreply,
         assign(socket,
           modal_mode: :view,
           viewing_application: application,
           editing_application: nil,
           deactivating_application: nil
         )}

      _error ->
        {:noreply, put_flash(socket, :error, "Could not load application.")}
    end
  end

  def handle_event("reveal_token", %{"id" => id}, socket) do
    user = socket.assigns.current_user

    with {:ok, application} <- get_application_with_token(id, user),
         token when is_binary(token) <- application.client_token do
      {:noreply, put_revealed_token(socket, application.id, token)}
    else
      _error ->
        {:noreply, put_flash(socket, :error, "Could not reveal token.")}
    end
  end

  def handle_event("rotate_token", %{"id" => id}, socket) do
    user = socket.assigns.current_user

    with {:ok, application} <- get_application(id, user),
         {:ok, application} <-
           application
           |> Ash.Changeset.for_update(:rotate_token, %{}, actor: user)
           |> Ash.update(),
         token <- reveal_loaded_token(application, user) do
      {:noreply,
       socket
       |> put_flash(:info, "Application token rotated.")
       |> put_revealed_token(application.id, token)
       |> load_applications(user)}
    else
      _error ->
        {:noreply, put_flash(socket, :error, "Could not rotate token.")}
    end
  end

  def handle_event("archive_application", %{"id" => id}, socket) do
    manage_application(socket, id, :archive, "Application archived.")
  end

  def handle_event("restore_application", %{"id" => id}, socket) do
    manage_application(socket, id, :restore, "Application restored.")
  end

  def handle_event("request_deactivate_application", %{"id" => id}, socket) do
    user = socket.assigns.current_user

    case get_application(id, user) do
      {:ok, application} ->
        {:noreply,
         assign(socket,
           modal_mode: :confirm_deactivate,
           deactivating_application: application,
           editing_application: nil,
           viewing_application: nil
         )}

      _error ->
        {:noreply, put_flash(socket, :error, "Could not load application.")}
    end
  end

  def handle_event("confirm_deactivate_application", %{"id" => id}, socket) do
    socket
    |> close_modal()
    |> manage_application(id, :deactivate, "Application deactivated.")
  end

  def handle_event("activate_application", %{"id" => id}, socket) do
    manage_application(socket, id, :activate, "Application activated.")
  end

  defp load_organizations(socket, user, true) do
    organizations =
      Organization
      |> Ash.Query.for_read(:list_for_platform, %{}, actor: user)
      |> Ash.read!()

    assign(socket, organizations: organizations, org_admin_organization: nil)
  end

  defp load_organizations(socket, user, false) do
    membership =
      OrganizationMembership
      |> Ash.Query.for_read(:for_user, %{user_id: user.id}, actor: user)
      |> Ash.Query.load(:organization)
      |> Ash.read!()
      |> List.first()

    organization = membership && membership.organization

    assign(socket,
      organizations: List.wrap(organization),
      org_admin_organization: organization
    )
  end

  defp assign_forms(socket) do
    create_data = Forms.new_data()

    assign(socket,
      create_form_data: create_data,
      create_form: Forms.form_for(create_data),
      edit_form_data: nil,
      edit_form: nil
    )
  end

  defp load_applications(socket, user) do
    applications =
      if socket.assigns.platform_owner? do
        platform_applications(user, socket.assigns.selected_organization_id)
      else
        organization_applications(user, socket.assigns.org_admin_organization)
      end

    assign(socket, :applications, applications)
  end

  defp platform_applications(user, "all") do
    SsoApplication
    |> Ash.Query.for_read(:list_for_platform, %{}, actor: user)
    |> Ash.Query.load(:organization)
    |> Ash.read!()
  end

  defp platform_applications(user, organization_id) do
    SsoApplication
    |> Ash.Query.for_read(:list_for_organization, %{organization_id: organization_id},
      actor: user
    )
    |> Ash.Query.load(:organization)
    |> Ash.read!()
  end

  defp organization_applications(_user, nil), do: []

  defp organization_applications(user, organization) do
    SsoApplication
    |> Ash.Query.for_read(:list_for_organization, %{organization_id: organization.id},
      actor: user
    )
    |> Ash.Query.load(:organization)
    |> Ash.read!()
  end

  defp get_application(id, user) do
    SsoApplication
    |> Ash.Query.for_read(:read, %{}, actor: user)
    |> Ash.Query.filter(id == ^id)
    |> Ash.Query.load(:organization)
    |> Ash.read_one()
  end

  defp get_application_with_token(id, user) do
    SsoApplication
    |> Ash.Query.for_read(:read, %{}, actor: user)
    |> Ash.Query.filter(id == ^id)
    |> Ash.Query.load([:organization, :client_token])
    |> Ash.read_one()
  end

  defp manage_application(socket, id, action, success_message) do
    user = socket.assigns.current_user

    with {:ok, application} <- get_application(id, user),
         {:ok, _application} <-
           application
           |> Ash.Changeset.for_update(action, %{}, actor: user)
           |> Ash.update() do
      {:noreply,
       socket
       |> put_flash(:info, success_message)
       |> load_applications(user)}
    else
      _error ->
        {:noreply, put_flash(socket, :error, "Could not update application.")}
    end
  end

  defp update_active_form(%{assigns: %{modal_mode: :create}} = socket, params) do
    data = Forms.update_data(socket.assigns.create_form_data, params)

    assign(socket,
      create_form_data: data,
      create_form: Forms.form_for(data)
    )
  end

  defp update_active_form(%{assigns: %{modal_mode: :edit}} = socket, params) do
    data = Forms.update_data(socket.assigns.edit_form_data, params)

    assign(socket,
      edit_form_data: data,
      edit_form: Forms.form_for(data)
    )
  end

  defp update_active_form(socket, _params), do: socket

  defp update_active_form_list(%{assigns: %{modal_mode: :create}} = socket, field, action) do
    data = apply_list_action(socket.assigns.create_form_data, field, action)

    assign(socket,
      create_form_data: data,
      create_form: Forms.form_for(data)
    )
  end

  defp update_active_form_list(%{assigns: %{modal_mode: :edit}} = socket, field, action) do
    data = apply_list_action(socket.assigns.edit_form_data, field, action)

    assign(socket,
      edit_form_data: data,
      edit_form: Forms.form_for(data)
    )
  end

  defp update_active_form_list(socket, _field, _action), do: socket

  defp apply_list_action(data, field, :add) do
    Forms.add_list_item(data, field)
  end

  defp apply_list_action(data, field, {:remove, index}) do
    Forms.remove_list_item(data, field, index)
  end

  defp reset_create_form(socket) do
    data = Forms.new_data()

    assign(socket,
      create_form_data: data,
      create_form: Forms.form_for(data)
    )
  end

  defp reveal_loaded_token(application, user) do
    case get_application_with_token(application.id, user) do
      {:ok, %{client_token: token}} -> token
      _ -> nil
    end
  end

  defp put_revealed_token(socket, _id, nil), do: socket

  defp put_revealed_token(socket, id, token) do
    update(socket, :revealed_tokens, &Map.put(&1, id, token))
  end

  defp close_modal(socket) do
    assign(socket,
      modal_mode: nil,
      editing_application: nil,
      viewing_application: nil,
      deactivating_application: nil,
      edit_form_data: nil,
      edit_form: nil
    )
  end
end
