defmodule Accountkit.Accounts.User.Actions.RequestSignupMagicLink do
  @moduledoc """
  Requests a magic link for signup and stores the submitted name in the token.
  """
  use Ash.Resource.Actions.Implementation

  alias Ash.ActionInput
  alias AshAuthentication.{Info, Jwt}

  @impl true
  def run(input, _opts, context) do
    strategy = Info.strategy!(input.resource, :magic_link)
    email = input |> ActionInput.get_argument(:email) |> to_string()
    name = input |> ActionInput.get_argument(:name) |> to_string() |> String.trim()

    with {sender, send_opts} <- strategy.sender,
         {:ok, token, _claims} <-
           Jwt.token_for_resource(
             strategy.resource,
             %{
               "act" => strategy.sign_in_action_name,
               "identity" => email,
               "name" => name
             },
             Keyword.merge(Ash.Context.to_opts(context),
               token_lifetime: strategy.token_lifetime,
               purpose: :magic_link
             ),
             context
           ) do
      send_opts =
        Keyword.merge(send_opts,
          tenant: context.tenant,
          source_context: context.source_context
        )

      sender.send(email, token, send_opts)
      :ok
    else
      :error -> {:error, "Could not create magic link"}
      error -> error
    end
  end
end
