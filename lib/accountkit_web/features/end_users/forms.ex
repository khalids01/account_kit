defmodule AccountkitWeb.Features.EndUsers.Forms do
  @auth_methods ~w(password magic_link oauth google facebook linkedin)
  @sorts ~w(newest oldest)
  @statuses ~w(all active banned)
  @tabs ~w(users archived)

  def default_filters do
    %{
      "tab" => "users",
      "search" => "",
      "organization_id" => "all",
      "status" => "all",
      "auth_methods" => [],
      "sort" => "newest",
      "page" => "1"
    }
  end

  def normalize_filters(params, current \\ default_filters()) do
    current
    |> Map.merge(string_keys(params || %{}))
    |> normalize()
  end

  def edit_form(end_user) do
    data = %{
      "name" => end_user.name || "",
      "phone" => end_user.phone || ""
    }

    Phoenix.Component.to_form(data, as: :end_user)
  end

  def attrs_for_update(params) do
    %{
      name: params["name"] |> to_string() |> String.trim(),
      phone: normalize_blank(params["phone"])
    }
  end

  def auth_methods, do: @auth_methods

  defp normalize(filters) do
    tab = pick(filters["tab"], @tabs, "users")

    %{
      "tab" => tab,
      "search" => filters["search"] |> to_string() |> String.trim(),
      "organization_id" => normalize_blank(filters["organization_id"]) || "all",
      "status" => pick(filters["status"], @statuses, "all"),
      "auth_methods" => normalize_auth_methods(filters["auth_methods"]),
      "sort" => pick(filters["sort"], @sorts, "newest"),
      "page" => normalize_page(filters["page"])
    }
  end

  defp normalize_auth_methods(values) when is_list(values) do
    Enum.filter(values, &(&1 in @auth_methods))
  end

  defp normalize_auth_methods(value) when is_binary(value) and value in @auth_methods, do: [value]
  defp normalize_auth_methods(_value), do: []

  defp normalize_page(value) do
    value
    |> to_string()
    |> Integer.parse()
    |> case do
      {page, ""} when page > 0 -> Integer.to_string(page)
      _ -> "1"
    end
  end

  defp pick(value, allowed, fallback), do: if(value in allowed, do: value, else: fallback)

  defp normalize_blank(value) when is_binary(value) do
    value = String.trim(value)
    if value == "", do: nil, else: value
  end

  defp normalize_blank(_value), do: nil

  defp string_keys(map) do
    Map.new(map, fn {key, value} -> {to_string(key), value} end)
  end
end
