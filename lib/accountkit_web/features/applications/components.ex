defmodule AccountkitWeb.Features.Applications.Components do
  @moduledoc false

  use Phoenix.Component

  import AccountkitWeb.Components.UI.Icon, only: [icon: 1]

  alias Accountkit.Accounts.SsoApplication

  attr :applications, :list, required: true

  def applications_grid(assigns) do
    ~H"""
    <div
      :if={@applications != []}
      id="applications-card-grid"
      class="grid gap-4 xl:grid-cols-2 2xl:grid-cols-3"
    >
      <.application_card
        :for={application <- @applications}
        application={application}
        id={"application-card-#{application.id}"}
      />
    </div>

    <div
      :if={@applications == []}
      class="rounded-2xl border border-dashed border-base-300 bg-base-100 p-10 text-center shadow-sm"
    >
      <div class="mx-auto flex size-12 items-center justify-center rounded-2xl bg-primary/10 text-primary">
        <.icon name="hero-window" class="size-6" />
      </div>
      <h3 class="mt-4 font-semibold">No applications yet.</h3>
      <p class="mt-1 text-sm text-base-content/60">Create an SSO application to get started.</p>
    </div>
    """
  end

  attr :application, SsoApplication, required: true
  attr :id, :string, required: true

  defp application_card(assigns) do
    ~H"""
    <article
      id={@id}
      data-application-card
      class="group rounded-2xl border border-base-300 bg-base-100 p-4 shadow-sm transition hover:border-primary/40 hover:shadow-md"
    >
      <div class="flex items-start justify-between gap-4">
        <div class="flex min-w-0 items-center gap-3">
          <.application_avatar application={@application} size="large" />
          <div class="min-w-0">
            <h3 class="truncate text-base font-semibold">{@application.name}</h3>
            <p class="mt-0.5 truncate text-sm text-base-content/60">
              {primary_redirect_url(@application)}
            </p>
          </div>
        </div>

        <.application_actions_menu
          id={"application-actions-#{@application.id}"}
          application={@application}
        />
      </div>

      <div class="mt-4 flex flex-wrap gap-2">
        <.org_badge organization={@application.organization} />
        <.status_badges application={@application} />
      </div>

      <div class="mt-4 flex flex-wrap gap-1.5">
        <.auth_badge label="Password" enabled={@application.password_enabled} />
        <.auth_badge label="Magic link" enabled={@application.magic_link_enabled} />
        <.auth_badge
          label="Google"
          enabled={@application.google_enabled}
          configured={present?(@application.google_client_id)}
        />
        <.auth_badge
          label="Facebook"
          enabled={@application.facebook_enabled}
          configured={present?(@application.facebook_app_id)}
        />
        <.auth_badge
          label="LinkedIn"
          enabled={@application.linkedin_enabled}
          configured={present?(@application.linkedin_client_id)}
        />
      </div>

      <dl class="mt-5 grid gap-3 text-sm sm:grid-cols-2">
        <div class="rounded-xl bg-base-200/50 p-3">
          <dt class="text-xs uppercase tracking-wide text-base-content/50">Redirect URLs</dt>
          <dd class="mt-1 truncate font-medium">{count_label(@application.redirect_urls, "URL")}</dd>
        </div>
        <div class="rounded-xl bg-base-200/50 p-3">
          <dt class="text-xs uppercase tracking-wide text-base-content/50">Allowed origins</dt>
          <dd class="mt-1 truncate font-medium">
            {count_label(@application.allowed_origins, "origin")}
          </dd>
        </div>
      </dl>
    </article>
    """
  end

  attr :form, Phoenix.HTML.Form, required: true
  attr :event, :string, required: true
  attr :title, :string, required: true
  attr :submit_label, :string, required: true
  attr :organizations, :list, required: true
  attr :platform_owner?, :boolean, required: true

  def application_form_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 z-50 overflow-y-auto bg-black/50 p-4 backdrop-blur-sm">
      <div class="mx-auto my-6 flex max-h-[calc(100vh-3rem)] max-w-5xl flex-col overflow-hidden rounded-2xl border border-base-300 bg-base-100 shadow-2xl">
        <div class="flex items-center justify-between gap-4 border-b border-base-300 px-5 py-4">
          <div>
            <p class="text-xs font-semibold uppercase tracking-wide text-primary">SSO application</p>
            <h3 class="text-lg font-semibold">{@title}</h3>
          </div>
          <button type="button" phx-click="close_modal" class="btn btn-ghost btn-sm">
            <.icon name="hero-x-mark" class="size-4" />
            <span>Close</span>
          </button>
        </div>

        <.form
          for={@form}
          id={String.replace(@event, "_", "-") <> "-form"}
          phx-change="change_application_form"
          phx-submit={@event}
          class="flex min-h-0 flex-1 flex-col"
        >
          <div class="min-h-0 flex-1 overflow-y-auto px-5 py-5">
            <div class="grid gap-5 lg:grid-cols-[1fr_0.85fr]">
              <div class="space-y-5">
                <section class="rounded-2xl border border-base-300 bg-base-100 p-4">
                  <h4 class="font-semibold">Profile</h4>
                  <div class="mt-4 grid gap-4 md:grid-cols-2">
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
                    <.text_input
                      field={@form[:email_from_address]}
                      label="Email from address"
                      type="email"
                    />
                  </div>
                </section>

                <section class="rounded-2xl border border-base-300 bg-base-100 p-4">
                  <div class="space-y-5">
                    <.list_inputs
                      field_name="allowed_origins"
                      label="Allowed origins"
                      values={input_values(@form, :allowed_origins)}
                    />
                    <.list_inputs
                      field_name="redirect_urls"
                      label="Redirect URLs"
                      values={input_values(@form, :redirect_urls)}
                      required
                    />
                  </div>
                </section>
              </div>

              <div class="space-y-5">
                <section class="rounded-2xl border border-base-300 bg-base-100 p-4">
                  <h4 class="font-semibold">Authentication</h4>
                  <div class="mt-4 space-y-3">
                    <.toggle_input field={@form[:password_enabled]} label="Password" />
                    <.toggle_input field={@form[:magic_link_enabled]} label="Magic link email" />
                  </div>
                </section>

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
            </div>
          </div>

          <div class="flex justify-end gap-2 border-t border-base-300 bg-base-100 px-5 py-4">
            <button type="button" phx-click="close_modal" class="btn btn-ghost">Cancel</button>
            <button type="submit" class="btn btn-primary">{@submit_label}</button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  attr :application, SsoApplication, required: true
  attr :token, :string, default: nil

  def application_details_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 z-50 overflow-y-auto bg-black/50 p-4 backdrop-blur-sm">
      <div class="mx-auto my-6 max-w-5xl overflow-hidden rounded-2xl border border-base-300 bg-base-100 shadow-2xl">
        <div class="bg-base-200/60 px-5 py-5">
          <div class="flex items-start justify-between gap-4">
            <div class="flex min-w-0 items-center gap-4">
              <.application_avatar application={@application} size="xlarge" />
              <div class="min-w-0">
                <p class="text-xs font-semibold uppercase tracking-wide text-primary">
                  Application profile
                </p>
                <h3 class="truncate text-2xl font-semibold">{@application.name}</h3>
                <p class="mt-1 truncate text-sm text-base-content/60">
                  {primary_redirect_url(@application)}
                </p>
              </div>
            </div>
            <button type="button" phx-click="close_modal" class="btn btn-ghost btn-sm">
              <.icon name="hero-x-mark" class="size-4" />
              <span>Close</span>
            </button>
          </div>

          <div class="mt-5 flex flex-wrap gap-2">
            <.org_badge organization={@application.organization} />
            <.status_badges application={@application} />
          </div>
        </div>

        <div class="grid gap-5 p-5 lg:grid-cols-[1fr_0.9fr]">
          <section class="space-y-4">
            <.detail_panel title="Redirect URLs" values={@application.redirect_urls} />
            <.detail_panel title="Allowed origins" values={@application.allowed_origins} />
            <div class="rounded-2xl border border-base-300 p-4">
              <h4 class="font-semibold">Auth methods</h4>
              <div class="mt-3 flex flex-wrap gap-1.5">
                <.auth_badge label="Password" enabled={@application.password_enabled} />
                <.auth_badge label="Magic link" enabled={@application.magic_link_enabled} />
                <.auth_badge
                  label="Google"
                  enabled={@application.google_enabled}
                  configured={present?(@application.google_client_id)}
                />
                <.auth_badge
                  label="Facebook"
                  enabled={@application.facebook_enabled}
                  configured={present?(@application.facebook_app_id)}
                />
                <.auth_badge
                  label="LinkedIn"
                  enabled={@application.linkedin_enabled}
                  configured={present?(@application.linkedin_client_id)}
                />
              </div>
            </div>
          </section>

          <section class="space-y-4">
            <div class="rounded-2xl border border-base-300 p-4">
              <h4 class="font-semibold">Email sender</h4>
              <dl class="mt-3 space-y-3 text-sm">
                <div>
                  <dt class="text-xs uppercase tracking-wide text-base-content/50">Name</dt>
                  <dd class="mt-1 font-medium">{@application.email_from_name || "Not set"}</dd>
                </div>
                <div>
                  <dt class="text-xs uppercase tracking-wide text-base-content/50">Address</dt>
                  <dd class="mt-1 font-medium">{@application.email_from_address || "Not set"}</dd>
                </div>
              </dl>
            </div>

            <div class="rounded-2xl border border-base-300 p-4">
              <div class="flex items-center justify-between gap-3">
                <h4 class="font-semibold">Client token</h4>
                <div class="flex gap-2">
                  <button
                    type="button"
                    phx-click="reveal_token"
                    phx-value-id={@application.id}
                    class="btn btn-ghost btn-xs"
                  >
                    Reveal
                  </button>
                  <button
                    type="button"
                    phx-click="rotate_token"
                    phx-value-id={@application.id}
                    class="btn btn-warning btn-xs"
                  >
                    Rotate
                  </button>
                </div>
              </div>
              <div class="mt-3">
                <.token_value token={@token} />
              </div>
            </div>
          </section>
        </div>
      </div>
    </div>
    """
  end

  attr :application, SsoApplication, required: true

  def deactivate_confirmation_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 z-50 overflow-y-auto bg-black/50 p-4 backdrop-blur-sm">
      <div class="mx-auto my-20 max-w-lg rounded-2xl border border-amber-300 bg-base-100 p-5 shadow-2xl">
        <div class="flex gap-4">
          <div class="flex size-11 shrink-0 items-center justify-center rounded-2xl bg-amber-100 text-amber-700">
            <.icon name="hero-exclamation-triangle" class="size-6" />
          </div>
          <div>
            <h3 class="text-lg font-semibold">Deactivate {@application.name}?</h3>
            <p class="mt-2 text-sm text-base-content/70">
              This application will stop accepting new SSO traffic until it is activated again.
              Existing configuration and tokens will be kept.
            </p>
          </div>
        </div>

        <div class="mt-6 flex justify-end gap-2">
          <button type="button" phx-click="close_modal" class="btn btn-ghost">Cancel</button>
          <button
            type="button"
            phx-click="confirm_deactivate_application"
            phx-value-id={@application.id}
            class="btn btn-warning"
          >
            Deactivate application
          </button>
        </div>
      </div>
    </div>
    """
  end

  attr :application, SsoApplication, required: true
  attr :size, :string, default: "large"

  defp application_avatar(assigns) do
    ~H"""
    <div class={[
      "flex shrink-0 items-center justify-center overflow-hidden rounded-full border border-base-300 bg-primary text-primary-content shadow-sm",
      @size == "large" && "size-14 text-lg",
      @size == "xlarge" && "size-20 text-2xl"
    ]}>
      <img
        :if={present?(@application.logo_url)}
        src={@application.logo_url}
        alt=""
        class="size-full object-cover"
      />
      <span :if={!present?(@application.logo_url)} class="font-bold">
        {initial(@application.name)}
      </span>
    </div>
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

  attr :field_name, :string, required: true
  attr :label, :string, required: true
  attr :values, :list, required: true
  attr :required, :boolean, default: false

  defp list_inputs(assigns) do
    ~H"""
    <div>
      <div class="flex items-center justify-between gap-3">
        <label class="text-sm font-medium">{@label}</label>
        <button
          type="button"
          phx-click="add_form_list_item"
          phx-value-field={@field_name}
          class="btn btn-ghost btn-xs"
        >
          <.icon name="hero-plus" class="size-3.5" />
          <span>Add</span>
        </button>
      </div>

      <div class="mt-2 space-y-2">
        <div :for={{value, index} <- Enum.with_index(@values)} class="flex gap-2">
          <input
            type="text"
            name={"application[#{@field_name}][]"}
            value={value}
            required={@required and index == 0}
            class="input input-bordered w-full"
          />
          <button
            type="button"
            phx-click="remove_form_list_item"
            phx-value-field={@field_name}
            phx-value-index={index}
            disabled={length(@values) == 1}
            class="btn btn-ghost btn-square"
          >
            <.icon name="hero-trash" class="size-4" />
          </button>
        </div>
      </div>
    </div>
    """
  end

  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, required: true

  defp toggle_input(assigns) do
    ~H"""
    <label class="flex items-center justify-between gap-3 rounded-xl border border-base-300 p-3">
      <span class="text-sm font-medium">{@label}</span>
      <input
        type="checkbox"
        name={@field.name}
        value="true"
        checked={@field.value in [true, "true"]}
        class="toggle toggle-primary"
      />
    </label>
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
    <section class="rounded-2xl border border-base-300 bg-base-100 p-4">
      <.toggle_input field={@enabled} label={@title} />
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
    </section>
    """
  end

  attr :organization, :map, required: true

  defp org_badge(assigns) do
    ~H"""
    <span class="inline-flex items-center rounded-full border border-sky-300 bg-sky-50 px-2.5 py-1 text-xs font-semibold text-sky-800 dark:border-sky-400/40 dark:bg-sky-400/10 dark:text-sky-200">
      {@organization.name}
    </span>
    """
  end

  attr :application, SsoApplication, required: true

  defp status_badges(assigns) do
    ~H"""
    <span
      :if={is_nil(@application.archived_at)}
      class="inline-flex rounded-full border border-emerald-300 bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-800 dark:border-emerald-400/40 dark:bg-emerald-400/10 dark:text-emerald-200"
    >
      Active
    </span>
    <span
      :if={!is_nil(@application.archived_at)}
      class="inline-flex rounded-full border border-zinc-300 bg-zinc-100 px-2.5 py-1 text-xs font-semibold text-zinc-700 dark:border-zinc-500/50 dark:bg-zinc-500/10 dark:text-zinc-200"
    >
      Archived
    </span>
    <span
      :if={!is_nil(@application.deactivated_at)}
      class="inline-flex rounded-full border border-amber-300 bg-amber-50 px-2.5 py-1 text-xs font-semibold text-amber-800 dark:border-amber-400/40 dark:bg-amber-400/10 dark:text-amber-200"
    >
      Deactivated
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
    <code :if={@token} class="block max-w-full overflow-x-auto rounded-xl bg-base-200 p-3 text-xs">
      {@token}
    </code>
    <span :if={!@token} class="text-sm text-base-content/50">Hidden</span>
    """
  end

  attr :id, :string, required: true
  attr :application, SsoApplication, required: true

  defp application_actions_menu(assigns) do
    ~H"""
    <details id={@id} data-application-menu class="group relative">
      <summary class="inline-flex size-9 cursor-pointer list-none items-center justify-center rounded-xl border border-base-300 bg-base-100 shadow-sm transition hover:border-primary/60 hover:bg-base-200 focus:outline-none focus:ring-2 focus:ring-primary/40 [&::-webkit-details-marker]:hidden">
        <span class="sr-only">Application actions</span>
        <.icon name="hero-ellipsis-horizontal" class="size-5" />
      </summary>

      <div class="absolute right-0 top-full z-40 mt-2 w-56 overflow-hidden rounded-xl border border-base-300 bg-base-100 p-2 text-sm shadow-xl">
        <.menu_button icon="hero-eye" label="View" event="view_application" id={@application.id} />
        <.menu_button
          icon="hero-pencil-square"
          label="Edit"
          event="edit_application"
          id={@application.id}
        />
        <.menu_button
          icon="hero-archive-box"
          label={if is_nil(@application.archived_at), do: "Archive", else: "Restore"}
          event={
            if is_nil(@application.archived_at),
              do: "archive_application",
              else: "restore_application"
          }
          id={@application.id}
        />
        <.menu_button
          icon={
            if is_nil(@application.deactivated_at), do: "hero-no-symbol", else: "hero-play-circle"
          }
          label={if is_nil(@application.deactivated_at), do: "Deactivate", else: "Activate"}
          event={
            if is_nil(@application.deactivated_at),
              do: "request_deactivate_application",
              else: "activate_application"
          }
          id={@application.id}
          danger={is_nil(@application.deactivated_at)}
        />
      </div>
    </details>
    """
  end

  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :event, :string, required: true
  attr :id, :string, required: true
  attr :danger, :boolean, default: false

  defp menu_button(assigns) do
    ~H"""
    <button
      type="button"
      role="menuitem"
      phx-click={@event}
      phx-value-id={@id}
      class={[
        "flex w-full items-center gap-2 rounded-lg px-3 py-2 text-base-content/80 transition hover:bg-base-200 hover:text-base-content",
        @danger && "text-amber-700 dark:text-amber-300"
      ]}
    >
      <.icon name={@icon} class="size-4" />
      <span>{@label}</span>
    </button>
    """
  end

  attr :title, :string, required: true
  attr :values, :list, required: true

  defp detail_panel(assigns) do
    ~H"""
    <div class="rounded-2xl border border-base-300 p-4">
      <h4 class="font-semibold">{@title}</h4>
      <div :if={@values == []} class="mt-3 text-sm text-base-content/50">None configured</div>
      <ul :if={@values != []} class="mt-3 space-y-2">
        <li :for={value <- @values} class="rounded-xl bg-base-200/60 px-3 py-2 text-sm">
          {value}
        </li>
      </ul>
    </div>
    """
  end

  defp input_values(form, field) do
    form[field].value
    |> case do
      values when is_list(values) and values != [] -> values
      value when is_binary(value) and value != "" -> [value]
      _ -> [""]
    end
  end

  defp primary_redirect_url(%{redirect_urls: [url | _]}), do: url
  defp primary_redirect_url(_), do: "No redirect URL configured"

  defp count_label([], label), do: "No #{label}s"
  defp count_label([one], _label), do: one
  defp count_label(values, label), do: "#{length(values)} #{label}s"

  defp initial(nil), do: "A"
  defp initial(""), do: "A"
  defp initial(name), do: name |> String.trim() |> String.first() |> String.upcase()

  defp present?(value), do: is_binary(value) and String.trim(value) != ""

  defp status_label(false, _configured), do: "Off"
  defp status_label(true, false), do: "Needs config"
  defp status_label(true, true), do: "On"
end
