defmodule AccountkitWeb.Features.ApplicationSso.Components do
  @moduledoc false

  use Phoenix.Component

  import AccountkitWeb.Components.UI.Icon, only: [icon: 1]

  alias AccountkitWeb.Layouts
  alias Phoenix.LiveView.JS

  attr :client, :map, default: nil
  attr :title, :string, required: true
  attr :flash, :map, required: true
  slot :inner_block, required: true

  def auth_shell(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={nil}>
      <section class="mx-auto flex min-h-screen max-w-md items-center px-6 py-16">
        <div class="sso-auth-form w-full rounded-2xl border border-base-300 bg-base-100 p-8 shadow-sm [&_label]:!text-base-content [&_input:not([type=hidden])]:!border-base-300 [&_input:not([type=hidden])]:!bg-base-200 [&_input:not([type=hidden])]:!text-base-content [&_input:not([type=hidden])::placeholder]:!text-base-content/50 [&_input.border-rose-400]:!border-error [&_p.text-rose-600]:!text-error">
          <div class="mb-8 text-center">
            <img
              :if={@client && @client.logoUrl}
              src={@client.logoUrl}
              alt={@client.name <> " logo"}
              class="mx-auto mb-4 max-h-16 max-w-36 object-contain"
            />
            <p :if={@client} class="text-sm font-medium text-base-content/60">
              {@client.name}
            </p>
            <h1 class="mt-3 text-2xl font-bold tracking-tight">{@title}</h1>
          </div>

          {render_slot(@inner_block)}
        </div>
      </section>
    </Layouts.app>
    """
  end

  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, required: true
  attr :placeholder, :string, default: nil
  attr :autocomplete, :string, default: nil
  attr :required, :boolean, default: false

  def password_input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns =
      assigns
      |> assign(:errors, Enum.map(errors, &translate_error(&1)))
      |> assign(:id, field.id)
      |> assign(:name, field.name)
      |> assign(:value, field.value)
      |> assign(:toggle_icon_id, "#{field.id}-toggle-icon")

    ~H"""
    <div>
      <label for={@id} class="block text-sm font-semibold leading-6 text-zinc-800 dark:text-zinc-200">
        {@label}
      </label>

      <div class="relative mt-2">
        <input
          type="password"
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value("password", @value)}
          placeholder={@placeholder}
          autocomplete={@autocomplete}
          required={@required}
          phx-debounce="blur"
          class={[
            "block w-full h-10 border rounded-lg py-1 ps-2 pe-10 text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 dark:text-zinc-200",
            @errors == [] && "border-zinc-300 focus:border-zinc-400",
            @errors != [] && "border-rose-400 focus:border-rose-400"
          ]}
        />

        <button
          type="button"
          class="absolute inset-y-0 end-0 flex items-center pe-3 text-base-content/60 hover:text-base-content focus:outline-none"
          aria-label="Toggle password visibility"
          phx-click={
            JS.toggle_class("hero-eye-slash", to: "##{@toggle_icon_id}")
            |> JS.toggle_attribute({"type", "password", "text"}, to: "##{@id}")
          }
        >
          <.icon name="hero-eye" id={@toggle_icon_id} class="size-5" />
        </button>
      </div>

      <p :for={msg <- @errors} class="mt-3 flex gap-3 text-sm leading-6 text-rose-600">
        <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
        {msg}
      </p>
    </div>
    """
  end

  defp translate_error({msg, opts}) do
    if count = opts[:count] do
      Gettext.dngettext(AccountkitWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(AccountkitWeb.Gettext, "errors", msg, opts)
    end
  end
end
