defmodule AccountkitWeb.Pages.ApplicationSsoHTML do
  @moduledoc """
  Sessionless pages for client-application SSO login and registration.
  """
  use AccountkitWeb, :html

  embed_templates "application_sso_html/*"

  def field_value(form, field) do
    form[field].value || ""
  end

  def field_errors(form, field) do
    form.source.errors
    |> Keyword.get_values(field)
    |> Enum.map(&AccountkitWeb.CoreComponents.translate_error/1)
  end

  attr :message, :string, required: true

  def sso_alert(assigns) do
    ~H"""
    <div role="alert" class="alert alert-error mb-5 text-sm">
      <span>{@message}</span>
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
  attr :autocomplete, :string, default: nil
  attr :placeholder, :string, default: nil
  attr :value, :string, default: nil
  attr :errors, :list, default: []
  attr :required, :boolean, default: false

  def sso_input(assigns) do
    ~H"""
    <div>
      <label for={@id} class="block text-sm font-semibold leading-6 text-base-content">
        {@label}
      </label>

      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        placeholder={@placeholder}
        autocomplete={@autocomplete}
        required={@required}
        class={[
          "mt-2 block h-10 w-full rounded-lg border bg-base-200 px-3 text-sm text-base-content focus:outline-none focus:ring-0",
          @errors == [] && "border-base-300 focus:border-base-content/50",
          @errors != [] && "border-error focus:border-error"
        ]}
      />

      <p :for={error <- @errors} class="mt-2 text-sm text-error">
        {error}
      </p>
    </div>
    """
  end
end
