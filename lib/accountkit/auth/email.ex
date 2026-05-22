defmodule Accountkit.Auth.Email do
  @moduledoc """
  Normalization and format validation for email addresses in auth flows.
  """

  @email_format ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/

  @doc """
  Trims whitespace and lowercases the email.
  """
  def normalize(email) do
    email
    |> to_string()
    |> String.trim()
    |> String.downcase()
  end

  @doc """
  Returns true when the string looks like a valid email address.
  """
  def valid?(email) when is_binary(email) do
    email != "" and Regex.match?(@email_format, email)
  end

  def valid?(_), do: false
end
