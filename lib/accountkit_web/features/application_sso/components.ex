defmodule AccountkitWeb.Features.ApplicationSso.Components do
  @moduledoc false

  use Phoenix.Component

  alias AccountkitWeb.Layouts

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
end
