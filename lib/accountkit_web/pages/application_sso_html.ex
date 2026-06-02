defmodule AccountkitWeb.Pages.ApplicationSsoHTML do
  @moduledoc """
  Sessionless pages for client-application SSO login and registration.
  """
  use AccountkitWeb, :html

  import AccountkitWeb.Components.UI.Icon, only: [icon: 1]

  embed_templates "application_sso_html/*"

  def field_value(form, field) do
    form[field].value || ""
  end

  def field_errors(form, field) do
    if form.source.action do
      form.source.errors
      |> Keyword.get_values(field)
      |> Enum.map(&AccountkitWeb.CoreComponents.translate_error/1)
    else
      []
    end
  end

  attr :message, :string, required: true

  def sso_toast(assigns) do
    ~H"""
    <div
      id="sso-toast"
      role="alert"
      aria-live="assertive"
      class="pointer-events-none fixed inset-x-0 top-4 z-50 flex justify-center px-4"
    >
      <div class="flash-alert pointer-events-auto flex max-w-md min-w-[min(100%,20rem)] items-center gap-3 rounded-xl border border-error/50 bg-base-100 p-3 text-sm font-medium text-base-content shadow-lg">
        <.icon name="hero-exclamation-circle" class="toast-icon size-5 shrink-0 text-error" />
        <p class="flex-1">{@message}</p>
        <button
          type="button"
          class="rounded-md p-1 hover:bg-base-content/10"
          aria-label="Dismiss"
          onclick="document.getElementById('sso-toast')?.remove()"
        >
          <.icon name="hero-x-mark" class="size-4" />
        </button>
      </div>
    </div>
    """
  end

  attr :prefix, :string, required: true
  attr :assigns, :map, required: true

  def hidden_context(assigns) do
    ~H"""
    <input type="hidden" name={"#{@prefix}[token]"} value={@assigns.token || ""} />
    <input type="hidden" name={"#{@prefix}[redirect_url]"} value={@assigns.redirect_url || ""} />
    <input
      :if={@assigns.callback_params}
      type="hidden"
      name={"#{@prefix}[callback_params]"}
      value={@assigns.callback_params}
    />
    """
  end

  attr :name, :string, required: true
  attr :id, :string, required: true
  attr :type, :string, required: true
  attr :label, :string, required: true
  attr :field, :string, required: true
  attr :validate, :string, required: true
  attr :autocomplete, :string, default: nil
  attr :placeholder, :string, default: nil
  attr :value, :string, default: nil
  attr :errors, :list, default: []
  attr :required, :boolean, default: false

  def sso_input(assigns) do
    assigns = assign(assigns, :server_error, List.first(assigns.errors))

    ~H"""
    <div class="sso-field">
      <label for={@id} class="block text-sm font-semibold leading-6 text-base-content">
        {@label}
      </label>

      <input
        type={@type}
        name={@name}
        id={@id}
        data-field={@field}
        data-validate={@validate}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        placeholder={@placeholder}
        autocomplete={@autocomplete}
        required={@required}
        class={[
          "sso-field-input mt-2 block h-10 w-full rounded-lg border bg-base-200 px-3 text-sm text-base-content focus:outline-none focus:ring-0",
          @errors == [] && "border-base-300 focus:border-base-content/50",
          @errors != [] && "border-error focus:border-error"
        ]}
      />

      <p
        data-error-for={@id}
        class={[
          "sso-field-error mt-2 text-sm text-error",
          is_nil(@server_error) && "hidden"
        ]}
      >
        {@server_error}
      </p>
    </div>
    """
  end

  attr :name, :string, required: true
  attr :id, :string, required: true
  attr :label, :string, required: true
  attr :field, :string, required: true
  attr :validate, :string, required: true
  attr :autocomplete, :string, default: nil
  attr :placeholder, :string, default: nil
  attr :value, :string, default: nil
  attr :errors, :list, default: []
  attr :required, :boolean, default: false

  def sso_password_input(assigns) do
    assigns = assign(assigns, :server_error, List.first(assigns.errors))

    ~H"""
    <div class="sso-field">
      <label for={@id} class="block text-sm font-semibold leading-6 text-base-content">
        {@label}
      </label>

      <div class="relative mt-2">
        <input
          type="password"
          name={@name}
          id={@id}
          data-field={@field}
          data-validate={@validate}
          value={Phoenix.HTML.Form.normalize_value("password", @value)}
          placeholder={@placeholder}
          autocomplete={@autocomplete}
          required={@required}
          class={[
            "sso-field-input block h-10 w-full rounded-lg border bg-base-200 py-1 ps-3 pe-10 text-sm text-base-content focus:outline-none focus:ring-0",
            @errors == [] && "border-base-300 focus:border-base-content/50",
            @errors != [] && "border-error focus:border-error"
          ]}
        />

        <button
          type="button"
          class="sso-password-toggle absolute inset-y-0 end-0 flex items-center pe-3 text-base-content/60 hover:text-base-content focus:outline-none"
          aria-label="Toggle password visibility"
          data-target={@id}
        >
          <.icon name="hero-eye" class="size-5" data-toggle-icon />
        </button>
      </div>

      <p
        data-error-for={@id}
        class={[
          "sso-field-error mt-2 text-sm text-error",
          is_nil(@server_error) && "hidden"
        ]}
      >
        {@server_error}
      </p>
    </div>
    """
  end
end
