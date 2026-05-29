defmodule AccountkitWeb.Pages.Admin.RateLimitsLive do
  @moduledoc """
  Admin UI for editing rate limit policies stored in Postgres.
  """
  use AccountkitWeb, :live_view

  alias Accountkit.RateLimit
  alias AccountkitWeb.Features.RateLimits.Components, as: RateLimitComponents
  alias AccountkitWeb.Features.RateLimits.Forms, as: RateLimitForms

  @impl true
  def mount(_params, _session, socket) do
    current_scope =
      case socket.assigns[:current_user] do
        %{__struct__: _} = user -> %{user: user}
        _ -> nil
      end

    {:ok,
     socket
     |> assign(:page_title, "Rate limits")
     |> assign(:current_scope, current_scope)
     |> load_policies()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-4xl px-6 py-10">
        <div class="mb-8">
          <h1 class="text-2xl font-bold tracking-tight">Rate limits</h1>
          <p class="mt-2 text-sm text-base-content/70">
            Configure how many magic link requests are allowed per IP and per email. Changes apply
            within about 30 seconds on each running node.
          </p>
        </div>

        <RateLimitComponents.policy_list policy_rows={@policy_rows} />
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("save", %{"id" => id, "policy" => params}, socket) do
    policy = Enum.find(socket.assigns.policies, &(&1.id == id))

    attrs = RateLimitForms.attrs_from_params(params)

    case Ash.update(policy, attrs, action: :update, authorize?: false) do
      {:ok, _policy} ->
        RateLimit.invalidate_policy_cache()

        {:noreply,
         socket
         |> put_flash(:info, "Saved #{policy.key}.")
         |> load_policies()}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Could not save rate limit policy.")}
    end
  end

  defp load_policies(socket) do
    policies = RateLimitForms.list_policies()
    policy_rows = RateLimitForms.policy_rows(policies)

    assign(socket, policies: policies, policy_rows: policy_rows)
  end
end
