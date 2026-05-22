defmodule AccountkitWeb.AuthOverrides do
  use AshAuthentication.Phoenix.Overrides

  override AshAuthentication.Phoenix.Components.Banner do
    set :href_url, "/"
    set :image_class, "h-12 w-auto"
    set :image_url, "/images/logo.svg"
    set :dark_image_url, nil
    set :text, nil
  end

  # First argument to `override` is the component name you are overriding.
  # The body contains any number of configurations you wish to override
  # Below are some examples

  # For a complete reference, see https://hexdocs.pm/ash_authentication_phoenix/ui-overrides.html

  # override AshAuthentication.Phoenix.Components.Banner do
  #   set :image_url, "https://media.giphy.com/media/g7GKcSzwQfugw/giphy.gif"
  #   set :text_class, "bg-red-500"
  # end

  # override AshAuthentication.Phoenix.Components.SignIn do
  #  set :show_banner, false
  # end
end
