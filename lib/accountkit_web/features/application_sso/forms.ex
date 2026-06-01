defmodule AccountkitWeb.Features.ApplicationSso.Forms do
  @moduledoc false

  import Ecto.Changeset
  import Phoenix.Component, only: [to_form: 2]

  alias Accountkit.Auth.Email

  @email_format ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/

  def login_form(params \\ %{}) do
    params
    |> login_changeset()
    |> to_form(as: :sso_login)
  end

  def register_form(params \\ %{}) do
    params
    |> register_changeset()
    |> to_form(as: :sso_register)
  end

  def login_changeset(params \\ %{}) do
    {%{}, %{email: :string, password: :string}}
    |> cast(params, [:email, :password])
    |> update_change(:email, &Email.normalize/1)
    |> validate_required([:email], message: "Enter your email address.")
    |> validate_required([:password], message: "Enter your password.")
    |> validate_format(:email, @email_format, message: "Enter a valid email address.")
  end

  def register_changeset(params \\ %{}) do
    {%{}, %{name: :string, email: :string, password: :string}}
    |> cast(params, [:name, :email, :password])
    |> update_change(:name, &trim/1)
    |> update_change(:email, &Email.normalize/1)
    |> validate_required([:name], message: "Enter your name.")
    |> validate_required([:email], message: "Enter your email address.")
    |> validate_required([:password], message: "Enter your password.")
    |> validate_format(:email, @email_format, message: "Enter a valid email address.")
    |> validate_length(:password, min: 8, message: "Password must be at least 8 characters long.")
  end

  def first_error(%Ecto.Changeset{errors: [{_field, {message, _opts}} | _]}), do: message
  def first_error(_changeset), do: "Please fix the highlighted fields."

  defp trim(value) when is_binary(value), do: String.trim(value)
  defp trim(value), do: value
end
