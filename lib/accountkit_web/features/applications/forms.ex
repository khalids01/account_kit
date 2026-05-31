defmodule AccountkitWeb.Features.Applications.Forms do
  @moduledoc false

  import Phoenix.Component, only: [to_form: 2]

  @boolean_fields ~w(
    password_enabled
    magic_link_enabled
    google_enabled
    facebook_enabled
    linkedin_enabled
  )

  @empty_data %{
    "organization_id" => "",
    "name" => "",
    "logo_url" => "",
    "allowed_origins" => [""],
    "redirect_urls" => [""],
    "email_from_name" => "",
    "email_from_address" => "",
    "password_enabled" => "true",
    "magic_link_enabled" => "true",
    "google_enabled" => "false",
    "google_client_id" => "",
    "google_client_secret" => "",
    "facebook_enabled" => "false",
    "facebook_app_id" => "",
    "facebook_app_secret" => "",
    "linkedin_enabled" => "false",
    "linkedin_client_id" => "",
    "linkedin_client_secret" => ""
  }

  def empty_data, do: @empty_data

  def new_data, do: @empty_data

  def new_form do
    form_for(new_data())
  end

  def edit_data(application) do
    @empty_data
    |> Map.merge(%{
      "name" => application.name,
      "logo_url" => application.logo_url || "",
      "allowed_origins" => list_or_blank(application.allowed_origins),
      "redirect_urls" => list_or_blank(application.redirect_urls),
      "email_from_name" => application.email_from_name || "",
      "email_from_address" => application.email_from_address || "",
      "password_enabled" => application.password_enabled,
      "magic_link_enabled" => application.magic_link_enabled,
      "google_enabled" => application.google_enabled,
      "google_client_id" => application.google_client_id || "",
      "facebook_enabled" => application.facebook_enabled,
      "facebook_app_id" => application.facebook_app_id || "",
      "linkedin_enabled" => application.linkedin_enabled,
      "linkedin_client_id" => application.linkedin_client_id || ""
    })
  end

  def form_for(data), do: to_form(data, as: :application)

  def update_data(data, params) do
    params = normalize_form_params(params)

    data
    |> Map.merge(params)
    |> ensure_list_field("allowed_origins")
    |> ensure_list_field("redirect_urls")
  end

  def add_list_item(data, field) when field in ["allowed_origins", "redirect_urls"] do
    Map.update(data, field, [""], &(&1 ++ [""]))
  end

  def remove_list_item(data, field, index) when field in ["allowed_origins", "redirect_urls"] do
    values =
      data
      |> Map.get(field, [""])
      |> List.delete_at(index)
      |> list_or_blank()

    Map.put(data, field, values)
  end

  def attrs_for_create(params, true, _organization_id) do
    case blank_to_nil(params["organization_id"]) do
      nil ->
        {:error, :missing_organization}

      organization_id ->
        {:ok, Map.put(attrs_for_update(params), :organization_id, organization_id)}
    end
  end

  def attrs_for_create(params, false, organization_id) do
    if is_nil(organization_id) do
      {:error, :missing_organization}
    else
      {:ok, Map.put(attrs_for_update(params), :organization_id, organization_id)}
    end
  end

  def attrs_for_update(params) do
    params = normalize_form_params(params)

    %{
      name: params["name"],
      logo_url: blank_to_nil(params["logo_url"]),
      allowed_origins: list_values(params["allowed_origins"]),
      redirect_urls: list_values(params["redirect_urls"]),
      email_from_name: blank_to_nil(params["email_from_name"]),
      email_from_address: blank_to_nil(params["email_from_address"]),
      password_enabled: checked?(params["password_enabled"]),
      magic_link_enabled: checked?(params["magic_link_enabled"]),
      google_enabled: checked?(params["google_enabled"]),
      google_client_id: blank_to_nil(params["google_client_id"]),
      facebook_enabled: checked?(params["facebook_enabled"]),
      facebook_app_id: blank_to_nil(params["facebook_app_id"]),
      linkedin_enabled: checked?(params["linkedin_enabled"]),
      linkedin_client_id: blank_to_nil(params["linkedin_client_id"])
    }
    |> put_secret(:google_client_secret, params["google_client_secret"])
    |> put_secret(:facebook_app_secret, params["facebook_app_secret"])
    |> put_secret(:linkedin_client_secret, params["linkedin_client_secret"])
  end

  def normalize_form_params(params) do
    params
    |> Map.put_new("allowed_origins", [""])
    |> Map.put_new("redirect_urls", [""])
    |> normalize_lists()
    |> normalize_booleans()
  end

  defp normalize_lists(params) do
    params
    |> Map.update!("allowed_origins", &list_or_blank/1)
    |> Map.update!("redirect_urls", &list_or_blank/1)
  end

  defp normalize_booleans(params) do
    Enum.reduce(@boolean_fields, params, fn field, acc ->
      Map.put_new(acc, field, "false")
    end)
  end

  defp ensure_list_field(data, field) do
    Map.update(data, field, [""], &list_or_blank/1)
  end

  defp list_or_blank(values) when is_list(values) do
    values =
      values
      |> Enum.map(&to_string/1)
      |> Enum.map(&String.trim/1)

    if values == [], do: [""], else: values
  end

  defp list_or_blank(value) when is_binary(value) do
    value
    |> String.split(["\n", ","], trim: true)
    |> list_or_blank()
  end

  defp list_or_blank(_), do: [""]

  defp list_values(values) do
    values
    |> list_or_blank()
    |> Enum.reject(&(&1 == ""))
  end

  defp put_secret(attrs, _key, value) when value in [nil, ""], do: attrs
  defp put_secret(attrs, key, value), do: Map.put(attrs, key, value)

  defp checked?(value), do: value in [true, "true", "on"]

  defp blank_to_nil(value) when value in [nil, ""], do: nil

  defp blank_to_nil(value) when is_binary(value) do
    value = String.trim(value)
    if value == "", do: nil, else: value
  end

  defp blank_to_nil(value), do: value
end
