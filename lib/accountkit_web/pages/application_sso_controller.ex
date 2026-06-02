defmodule AccountkitWeb.Pages.ApplicationSsoController do
  use AccountkitWeb, :controller

  alias AccountkitWeb.Features.ApplicationSso.{Auth, Clients, Forms}

  def login(conn, params) do
    render_page(conn, :login, params)
  end

  def register(conn, params) do
    render_page(conn, :register, params)
  end

  def submit_login(conn, %{"sso_login" => params}) do
    changeset = Forms.login_changeset(params)

    cond do
      not changeset.valid? ->
        render_page(conn, :login, params, form: Forms.login_form_with_action(params))

      true ->
        with {:ok, application} <- validate_password_client(params),
             {:ok, end_user} <- Auth.sign_in(application, params) do
          redirect_to_client(conn, params, end_user)
        else
          {:error, reason} ->
            render_page(conn, :login, params,
              form: Forms.login_form(params),
              error: Clients.error_message(reason)
            )
        end
    end
  end

  def submit_login(conn, _params) do
    render_page(conn, :login, %{}, error: "Something went wrong. Please try again.")
  end

  def submit_register(conn, %{"sso_register" => params}) do
    changeset = Forms.register_changeset(params)

    cond do
      not changeset.valid? ->
        render_page(conn, :register, params, form: Forms.register_form_with_action(params))

      true ->
        with {:ok, application} <- validate_password_client(params),
             {:ok, end_user} <- Auth.register(application, params) do
          redirect_to_client(conn, params, end_user)
        else
          {:error, :email_exists} ->
            render_page(conn, :register, params,
              form:
                Forms.register_form_with_email_error(
                  params,
                  Clients.error_message(:email_exists)
                )
            )

          {:error, reason} ->
            render_page(conn, :register, params,
              form: Forms.register_form(params),
              error: Clients.error_message(reason)
            )
        end
    end
  end

  def submit_register(conn, _params) do
    render_page(conn, :register, %{}, error: "Something went wrong. Please try again.")
  end

  defp render_page(conn, page, params, opts \\ []) do
    form =
      Keyword.get_lazy(opts, :form, fn ->
        case page do
          :login -> Forms.login_form(params)
          :register -> Forms.register_form(params)
        end
      end)

    assigns =
      params
      |> client_assigns()
      |> Map.merge(%{
        form: form,
        page_title: page_title(page),
        action_path: action_path(page),
        switch_path: switch_path(page, params),
        error: Keyword.get(opts, :error)
      })

    render(conn, page, assigns)
  end

  defp client_assigns(%{"token" => token, "redirect_url" => redirect_url} = params)
       when token != "" and redirect_url != "" do
    callback_params = Map.get(params, "callback_params")

    case Clients.validate_client(token, redirect_url) do
      {:ok, application} ->
        %{
          token: token,
          redirect_url: redirect_url,
          callback_params: callback_params,
          client: Clients.public_client(application),
          form_enabled: application.password_enabled,
          client_error: disabled_message(application)
        }

      {:error, reason} ->
        invalid_client_assigns(
          token,
          redirect_url,
          callback_params,
          Clients.error_message(reason)
        )
    end
  end

  defp client_assigns(_params) do
    invalid_client_assigns(nil, nil, nil, "Missing required parameters")
  end

  defp invalid_client_assigns(token, redirect_url, callback_params, message) do
    %{
      token: token,
      redirect_url: redirect_url,
      callback_params: callback_params,
      client: nil,
      form_enabled: false,
      client_error: message
    }
  end

  defp disabled_message(%{password_enabled: true}), do: nil
  defp disabled_message(_application), do: Clients.error_message(:password_disabled)

  defp validate_password_client(params) do
    with {:ok, application} <- Clients.validate_client(params["token"], params["redirect_url"]) do
      if application.password_enabled do
        {:ok, application}
      else
        {:error, :password_disabled}
      end
    end
  end

  defp redirect_to_client(conn, params, end_user) do
    redirect(conn,
      external:
        Clients.callback_url(
          params["redirect_url"],
          params["callback_params"],
          end_user.__metadata__.token
        )
    )
  end

  defp page_title(:login), do: "Sign in"
  defp page_title(:register), do: "Create account"

  defp action_path(:login), do: ~p"/sso/login"
  defp action_path(:register), do: ~p"/sso/register"

  defp switch_path(:login, params), do: sso_path(~p"/sso/register", params)
  defp switch_path(:register, params), do: sso_path(~p"/sso/login", params)

  defp sso_path(path, params) do
    query =
      %{}
      |> maybe_put("token", params["token"])
      |> maybe_put("redirect_url", params["redirect_url"])
      |> maybe_put("callback_params", params["callback_params"])

    case map_size(query) do
      0 -> path
      _count -> path <> "?" <> URI.encode_query(query)
    end
  end

  defp maybe_put(params, _key, value) when value in [nil, ""], do: params
  defp maybe_put(params, key, value), do: Map.put(params, key, value)
end
