defmodule AccountkitWeb.Pages.Dashboard.ApplicationsLive do
  use AccountkitWeb, :live_view

  alias Accountkit.Accounts.{Authorization, Organization, OrganizationMembership, SsoApplication}
  alias AccountkitWeb.Components.Sections.DashboardShell, as: DashboardLayout

  require Ash.Query

  @empty_form %{
    "organization_id" => "",
    "name" => "",
    "logo_url" => "",
    "allowed_origins" => "",
    "redirect_urls" => "",
    "email_from_name" => "",
    "email_from_address" => "",
    "password_enabled" => "true",
    "magic_link_enabled" => "true",
    "google_enabled" => "false",
    "google_client_id" => "",
    "google_client_secret" => "",
    "facebook_enabled" => "false",
    "facebook_app_id" => "",
    "facebook_app_secret" => "",
    "linkedin_enabled" => "false",
    "linkedin_client_id" => "",
    "linkedin_client_secret" => ""
  }

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
     |> assign(:editing_application, nil)
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
        </div>

        <.application_form
          id="create-application-form"
          form={@create_form}
          event="create_application"
          title="Create application"
          submit_label="Create application"
          organizations={@organizations}
          platform_owner?={@platform_owner?}
          editing?={false}
        />

        <.application_form
          :if={@editing_application}
          id="edit-application-form"
          form={@edit_form}
          event="update_application"
          title={"Edit #{@editing_application.name}"}
          submit_label="Update application"
          organizations={@organizations}
          platform_owner?={false}
          editing?={true}
        />

        <div class="hidden overflow-x-auto rounded-2xl border border-base-300 bg-base-100 shadow-sm lg:block">
          <table class="w-full text-left text-sm">
            <thead class="border-b border-base-300 bg-base-200/50 text-xs uppercase tracking-wide text-base-content/60">
              <tr>
                <th class="px-4 py-3 font-medium">Application</th>
                <th class="px-4 py-3 font-medium">Organization</th>
                <th class="px-4 py-3 font-medium">Auth</th>
                <th class="px-4 py-3 font-medium">Redirect URLs</th>
                <th class="px-4 py-3 font-medium">Token</th>
                <th class="px-4 py-3 font-medium"><span class="sr-only">Actions</span></th>
              </tr>
            </thead>
            <tbody class="divide-y divide-base-300">
              <tr :for={application <- @applications} id={"application-#{application.id}"}>
                <td class="px-4 py-3">
                  <div class="font-medium">{application.name}</div>
                  <div class="text-xs text-base-content/60">
                    {application.logo_url || "No logo URL"}
                  </div>
                </td>
                <td class="px-4 py-3"><.org_badge organization={application.organization} /></td>
                <td class="px-4 py-3">
                  <div class="flex flex-wrap gap-1.5">
                    <.auth_badge label="Password" enabled={application.password_enabled} />
                    <.auth_badge label="Magic link" enabled={application.magic_link_enabled} />
                    <.auth_badge
                      label="Google"
                      enabled={application.google_enabled}
                      configured={present?(application.google_client_id)}
                    />
                    <.auth_badge
                      label="Facebook"
                      enabled={application.facebook_enabled}
                      configured={present?(application.facebook_app_id)}
                    />
                    <.auth_badge
                      label="LinkedIn"
                      enabled={application.linkedin_enabled}
                      configured={present?(application.linkedin_client_id)}
                    />
                  </div>
                </td>
                <td class="max-w-xs px-4 py-3 text-base-content/70">
                  {Enum.join(application.redirect_urls, ", ")}
                </td>
                <td class="px-4 py-3">
                  <.token_value token={Map.get(@revealed_tokens, application.id)} />
                </td>
                <td class="px-4 py-3 text-right">
                  <.application_actions application={application} />
                </td>
              </tr>
              <tr :if={@applications == []}>
                <td colspan="6" class="px-4 py-8 text-center text-base-content/60">
                  No applications yet.
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="space-y-3 lg:hidden">
          <article
            :for={application <- @applications}
            id={"application-card-#{application.id}"}
            class="rounded-2xl border border-base-300 bg-base-100 p-4 shadow-sm"
          >
            <div class="flex items-start justify-between gap-3">
              <div class="min-w-0">
                <h3 class="truncate font-semibold">{application.name}</h3>
                <p class="mt-1 truncate text-sm text-base-content/70">
                  {application.logo_url || "No logo URL"}
                </p>
              </div>
              <.org_badge organization={application.organization} />
            </div>

            <div class="mt-4 flex flex-wrap gap-1.5">
              <.auth_badge label="Password" enabled={application.password_enabled} />
              <.auth_badge label="Magic link" enabled={application.magic_link_enabled} />
              <.auth_badge
                label="Google"
                enabled={application.google_enabled}
                configured={present?(application.google_client_id)}
              />
              <.auth_badge
                label="Facebook"
                enabled={application.facebook_enabled}
                configured={present?(application.facebook_app_id)}
              />
              <.auth_badge
                label="LinkedIn"
                enabled={application.linkedin_enabled}
                configured={present?(application.linkedin_client_id)}
              />
            </div>

            <dl class="mt-4 space-y-3 text-sm">
              <div>
                <dt class="text-xs uppercase tracking-wide text-base-content/50">Redirect URLs</dt>
                <dd class="mt-1 font-medium">{Enum.join(application.redirect_urls, ", ")}</dd>
              </div>
              <div>
                <dt class="text-xs uppercase tracking-wide text-base-content/50">Token</dt>
                <dd class="mt-1">
                  <.token_value token={Map.get(@revealed_tokens, application.id)} />
                </dd>
              </div>
            </dl>

            <div class="mt-4">
              <.application_actions application={application} />
            </div>
          </article>

          <div
            :if={@applications == []}
            class="rounded-2xl border border-base-300 bg-base-100 p-6 text-center text-sm text-base-content/60 shadow-sm"
          >
            No applications yet.
          </div>
        </div>
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

  def handle_event("create_application", %{"application" => params}, socket) do
    user = socket.assigns.current_user

    with {:ok, attrs} <- attrs_for_create(socket, params),
         {:ok, application} <-
           SsoApplication
           |> Ash.Changeset.for_create(:create, attrs, actor: user)
           |> Ash.create() do
      token = reveal_loaded_token(application, user)

      {:noreply,
       socket
       |> put_flash(:info, "Application created.")
       |> assign(:create_form, new_form())
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
        {:noreply,
         socket
         |> assign(:editing_application, application)
         |> assign(:edit_form, edit_form(application))}

      _error ->
        {:noreply, put_flash(socket, :error, "Could not load application.")}
    end
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, editing_application: nil, edit_form: nil)}
  end

  def handle_event("update_application", %{"application" => params}, socket) do
    user = socket.assigns.current_user
    application = socket.assigns.editing_application

    with attrs <- attrs_for_update(params),
         {:ok, _application} <-
           application
           |> Ash.Changeset.for_update(:update, attrs, actor: user)
           |> Ash.update() do
      {:noreply,
       socket
       |> put_flash(:info, "Application updated.")
       |> assign(editing_application: nil, edit_form: nil)
       |> load_applications(user)}
    else
      _error ->
        {:noreply, put_flash(socket, :error, "Could not update application.")}
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

  def handle_event("delete_application", %{"id" => id}, socket) do
    user = socket.assigns.current_user

    with {:ok, application} <- get_application(id, user),
         :ok <- Ash.destroy(application, actor: user) do
      {:noreply,
       socket
       |> put_flash(:info, "Application deleted.")
       |> update(:revealed_tokens, &Map.delete(&1, application.id))
       |> load_applications(user)}
    else
      _error ->
        {:noreply, put_flash(socket, :error, "Could not delete application.")}
    end
  end

  attr :id, :string, required: true
  attr :form, Phoenix.HTML.Form, required: true
  attr :event, :string, required: true
  attr :title, :string, required: true
  attr :submit_label, :string, required: true
  attr :organizations, :list, required: true
  attr :platform_owner?, :boolean, required: true
  attr :editing?, :boolean, required: true

  defp application_form(assigns) do
    ~H"""
    <section class="rounded-2xl border border-base-300 bg-base-100 p-4 shadow-sm">
      <div class="mb-4 flex items-center justify-between gap-3">
        <h3 class="text-base font-semibold">{@title}</h3>
        <button :if={@editing?} type="button" phx-click="cancel_edit" class="btn btn-ghost btn-sm">
          Cancel
        </button>
      </div>

      <.form for={@form} id={@id} phx-submit={@event} class="space-y-4">
        <div class="grid gap-4 md:grid-cols-2">
          <div :if={@platform_owner?}>
            <label class="text-sm font-medium">Organization</label>
            <select
              name={@form[:organization_id].name}
              value={@form[:organization_id].value}
              required
              class="select select-bordered mt-2 w-full"
            >
              <option value="">Choose organization</option>
              <option :for={organization <- @organizations} value={organization.id}>
                {organization.name}
              </option>
            </select>
          </div>

          <.text_input field={@form[:name]} label="Name" required />
          <.text_input field={@form[:logo_url]} label="Logo URL" />
          <.text_input field={@form[:email_from_name]} label="Email from name" />
          <.text_input field={@form[:email_from_address]} label="Email from address" type="email" />
        </div>

        <div class="grid gap-4 md:grid-cols-2">
          <.textarea_input field={@form[:allowed_origins]} label="Allowed origins" />
          <.textarea_input field={@form[:redirect_urls]} label="Redirect URLs" required />
        </div>

        <div class="grid gap-4 lg:grid-cols-3">
          <.provider_panel
            title="Core auth"
            fields={[
              {@form[:password_enabled], "Password"},
              {@form[:magic_link_enabled], "Magic link"}
            ]}
          />

          <.oauth_panel
            title="Google"
            enabled={@form[:google_enabled]}
            id_field={@form[:google_client_id]}
            secret_field={@form[:google_client_secret]}
            id_label="Google client ID"
            secret_label="Google client secret"
          />

          <.oauth_panel
            title="Facebook"
            enabled={@form[:facebook_enabled]}
            id_field={@form[:facebook_app_id]}
            secret_field={@form[:facebook_app_secret]}
            id_label="Facebook app ID"
            secret_label="Facebook app secret"
          />

          <.oauth_panel
            title="LinkedIn"
            enabled={@form[:linkedin_enabled]}
            id_field={@form[:linkedin_client_id]}
            secret_field={@form[:linkedin_client_secret]}
            id_label="LinkedIn client ID"
            secret_label="LinkedIn client secret"
          />
        </div>

        <div class="flex justify-end">
          <button type="submit" class="btn btn-primary">{@submit_label}</button>
        </div>
      </.form>
    </section>
    """
  end

  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, required: true
  attr :type, :string, default: "text"
  attr :required, :boolean, default: false

  defp text_input(assigns) do
    ~H"""
    <div>
      <label class="text-sm font-medium">{@label}</label>
      <input
        type={@type}
        name={@field.name}
        value={@field.value}
        required={@required}
        class="input input-bordered mt-2 w-full"
      />
    </div>
    """
  end

  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, required: true
  attr :required, :boolean, default: false

  defp textarea_input(assigns) do
    ~H"""
    <div>
      <label class="text-sm font-medium">{@label}</label>
      <textarea
        name={@field.name}
        required={@required}
        rows="3"
        class="textarea textarea-bordered mt-2 w-full"
      >{@field.value}</textarea>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :fields, :list, required: true

  defp provider_panel(assigns) do
    ~H"""
    <div class="rounded-xl border border-base-300 bg-base-200/30 p-4">
      <h4 class="text-sm font-semibold">{@title}</h4>
      <div class="mt-3 space-y-2">
        <label :for={{field, label} <- @fields} class="flex items-center gap-2 text-sm">
          <input
            type="checkbox"
            name={field.name}
            value="true"
            checked={field.value in [true, "true"]}
            class="checkbox checkbox-primary checkbox-sm"
          />
          <span>{label}</span>
        </label>
      </div>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :enabled, Phoenix.HTML.FormField, required: true
  attr :id_field, Phoenix.HTML.FormField, required: true
  attr :secret_field, Phoenix.HTML.FormField, required: true
  attr :id_label, :string, required: true
  attr :secret_label, :string, required: true

  defp oauth_panel(assigns) do
    ~H"""
    <div class="rounded-xl border border-base-300 bg-base-200/30 p-4">
      <label class="flex items-center gap-2 text-sm font-semibold">
        <input
          type="checkbox"
          name={@enabled.name}
          value="true"
          checked={@enabled.value in [true, "true"]}
          class="checkbox checkbox-primary checkbox-sm"
        />
        <span>{@title}</span>
      </label>

      <div class="mt-3 space-y-3">
        <input
          type="text"
          name={@id_field.name}
          value={@id_field.value}
          placeholder={@id_label}
          class="input input-bordered input-sm w-full"
        />
        <input
          type="password"
          name={@secret_field.name}
          value=""
          placeholder={@secret_label}
          class="input input-bordered input-sm w-full"
        />
      </div>
    </div>
    """
  end

  attr :organization, :map, required: true

  defp org_badge(assigns) do
    ~H"""
    <span class="inline-flex rounded-full border border-sky-300 bg-sky-50 px-2.5 py-1 text-xs font-semibold text-sky-800 dark:border-sky-400/40 dark:bg-sky-400/10 dark:text-sky-200">
      {@organization.name}
    </span>
    """
  end

  attr :label, :string, required: true
  attr :enabled, :boolean, required: true
  attr :configured, :boolean, default: true

  defp auth_badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex rounded-full border px-2.5 py-1 text-xs font-semibold",
      @enabled && @configured &&
        "border-emerald-300 bg-emerald-50 text-emerald-800 dark:border-emerald-400/40 dark:bg-emerald-400/10 dark:text-emerald-200",
      @enabled && !@configured &&
        "border-amber-300 bg-amber-50 text-amber-800 dark:border-amber-400/40 dark:bg-amber-400/10 dark:text-amber-200",
      !@enabled &&
        "border-zinc-300 bg-zinc-100 text-zinc-700 dark:border-zinc-500/50 dark:bg-zinc-500/10 dark:text-zinc-200"
    ]}>
      {@label}: {status_label(@enabled, @configured)}
    </span>
    """
  end

  attr :token, :string, default: nil

  defp token_value(assigns) do
    ~H"""
    <code :if={@token} class="block max-w-xs overflow-x-auto rounded-lg bg-base-200 p-2 text-xs">
      {@token}
    </code>
    <span :if={!@token} class="text-xs text-base-content/50">Hidden</span>
    """
  end

  attr :application, SsoApplication, required: true

  defp application_actions(assigns) do
    ~H"""
    <div class="flex flex-wrap justify-end gap-2">
      <button
        type="button"
        phx-click="edit_application"
        phx-value-id={@application.id}
        class="btn btn-ghost btn-xs"
      >
        Edit
      </button>
      <button
        type="button"
        phx-click="reveal_token"
        phx-value-id={@application.id}
        class="btn btn-ghost btn-xs"
      >
        Reveal token
      </button>
      <button
        type="button"
        phx-click="rotate_token"
        phx-value-id={@application.id}
        class="btn btn-warning btn-xs"
      >
        Rotate token
      </button>
      <button
        type="button"
        phx-click="delete_application"
        phx-value-id={@application.id}
        class="btn btn-error btn-xs"
      >
        Delete
      </button>
    </div>
    """
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
    assign(socket, create_form: new_form(), edit_form: nil)
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

  defp attrs_for_create(socket, params) do
    organization_id =
      if socket.assigns.platform_owner? do
        blank_to_nil(params["organization_id"])
      else
        socket.assigns.org_admin_organization && socket.assigns.org_admin_organization.id
      end

    if is_nil(organization_id) do
      {:error, :missing_organization}
    else
      {:ok, Map.put(attrs_for_update(params), :organization_id, organization_id)}
    end
  end

  defp attrs_for_update(params) do
    %{
      name: params["name"],
      logo_url: blank_to_nil(params["logo_url"]),
      allowed_origins: lines(params["allowed_origins"]),
      redirect_urls: lines(params["redirect_urls"]),
      email_from_name: blank_to_nil(params["email_from_name"]),
      email_from_address: blank_to_nil(params["email_from_address"]),
      password_enabled: checked?(params["password_enabled"]),
      magic_link_enabled: checked?(params["magic_link_enabled"]),
      google_enabled: checked?(params["google_enabled"]),
      google_client_id: blank_to_nil(params["google_client_id"]),
      facebook_enabled: checked?(params["facebook_enabled"]),
      facebook_app_id: blank_to_nil(params["facebook_app_id"]),
      linkedin_enabled: checked?(params["linkedin_enabled"]),
      linkedin_client_id: blank_to_nil(params["linkedin_client_id"])
    }
    |> put_secret(:google_client_secret, params["google_client_secret"])
    |> put_secret(:facebook_app_secret, params["facebook_app_secret"])
    |> put_secret(:linkedin_client_secret, params["linkedin_client_secret"])
  end

  defp put_secret(attrs, _key, value) when value in [nil, ""], do: attrs
  defp put_secret(attrs, key, value), do: Map.put(attrs, key, value)

  defp new_form do
    to_form(@empty_form, as: :application)
  end

  defp edit_form(application) do
    @empty_form
    |> Map.merge(%{
      "name" => application.name,
      "logo_url" => application.logo_url || "",
      "allowed_origins" => Enum.join(application.allowed_origins, "\n"),
      "redirect_urls" => Enum.join(application.redirect_urls, "\n"),
      "email_from_name" => application.email_from_name || "",
      "email_from_address" => application.email_from_address || "",
      "password_enabled" => application.password_enabled,
      "magic_link_enabled" => application.magic_link_enabled,
      "google_enabled" => application.google_enabled,
      "google_client_id" => application.google_client_id || "",
      "facebook_enabled" => application.facebook_enabled,
      "facebook_app_id" => application.facebook_app_id || "",
      "linkedin_enabled" => application.linkedin_enabled,
      "linkedin_client_id" => application.linkedin_client_id || ""
    })
    |> to_form(as: :application)
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

  defp lines(value) when is_binary(value) do
    value
    |> String.split(["\n", ","], trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp lines(_), do: []

  defp checked?(value), do: value in [true, "true", "on"]

  defp blank_to_nil(value) when value in [nil, ""], do: nil

  defp blank_to_nil(value) when is_binary(value) do
    value = String.trim(value)
    if value == "", do: nil, else: value
  end

  defp blank_to_nil(value), do: value

  defp present?(value), do: is_binary(value) and String.trim(value) != ""

  defp status_label(false, _configured), do: "Off"
  defp status_label(true, false), do: "Needs config"
  defp status_label(true, true), do: "On"
end
