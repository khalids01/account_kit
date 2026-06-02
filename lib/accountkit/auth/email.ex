defmodule Accountkit.Auth.Email do
  @moduledoc """
  Email normalization and validation for auth flows.
  """

  @email_format ~r/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/

  @doc """
  Trims whitespace and lowercases the email.
  """
  def normalize(email) do
    email
    |> to_string()
    |> String.trim()
    |> String.downcase()
  end

  def valid?(email) do
    email = normalize(email)

    Regex.match?(@email_format, email) and
      email
      |> String.split("@")
      |> case do
        [_local, domain] -> valid_domain?(domain)
        _parts -> false
      end
  end

  def validate(email) do
    email = normalize(email)

    if valid?(email) do
      {:ok, email}
    else
      {:error, :invalid_email}
    end
  end

  def format_regex, do: @email_format

  defp valid_domain?(domain) do
    parts = String.split(domain, ".")
    tld = List.last(parts)

    length(parts) >= 2 and Enum.all?(parts, &(&1 != "")) and byte_size(tld) >= 2
  end
end
