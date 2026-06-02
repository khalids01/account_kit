defmodule AccountkitWeb.Pages.SsoDocsHTML do
  @moduledoc """
  Static HTML documentation for Application SSO integration.
  """
  use AccountkitWeb, :html

  embed_templates "sso_docs_html/*"

  def html_login_link_example do
    ~S|<a href="https://accountkit.example/sso/login?token=YOUR_CLIENT_TOKEN&redirect_url=https%3A%2F%2Fapp.example.com%2Fauth%2Fcallback">Sign in</a>|
  end

  def callback_handler_example do
    """
    // On /auth/callback
    const params = new URLSearchParams(window.location.search);
    const token = params.get('auth_token');
    const expiresIn = Number(params.get('expires_in')) || 60 * 60 * 24 * 14;

    if (token) {
      document.cookie = 'sso_auth_token=' + token + '; path=/; max-age=' + expiresIn + '; SameSite=Lax';
      history.replaceState({}, '', '/profile');
      await fetchUser(token);
    }
    """
    |> String.trim()
  end

  def me_response_example do
    """
    {
      "success": true,
      "user": {
        "id": "0af40173-5fc6-4d4d-bfed-9afc170635e9",
        "name": "Jane Doe",
        "email": "jane@example.com",
        "phone": null,
        "authMethods": ["password"]
      }
    }
    """
    |> String.trim()
  end

  def end_to_end_example do
    """
    const CLIENT_TOKEN = 'your_client_token';
    const CALLBACK = 'https://app.example.com/auth/callback';
    const ACCOUNTKIT = 'https://accountkit.example';

    function loginUrl() {
      const q = new URLSearchParams({ token: CLIENT_TOKEN, redirect_url: CALLBACK });
      return ACCOUNTKIT + '/sso/login?' + q.toString();
    }

    async function handleCallback() {
      const params = new URLSearchParams(location.search);
      const token = params.get('auth_token');
      if (!token) return;

      document.cookie = 'sso_auth_token=' + token + '; path=/; max-age=' + params.get('expires_in') + '; SameSite=Lax';
      history.replaceState({}, '', '/');

      const res = await fetch(ACCOUNTKIT + '/api/rest/auth/me', {
        headers: { Authorization: 'Bearer ' + token },
      });
      const { user } = await res.json();
      console.log('Signed in as', user.email);
    }
    """
    |> String.trim()
  end

  @nav_sections [
    %{id: "overview", label: "Overview"},
    %{id: "setup", label: "Setup"},
    %{id: "redirect-flow", label: "Redirect flow"},
    %{id: "callback", label: "Callback"},
    %{id: "session", label: "Store session"},
    %{id: "api-reference", label: "Get current user"},
    %{id: "logout", label: "Logout"},
    %{id: "rest-alternative", label: "REST alternative"},
    %{id: "security", label: "Security"}
  ]

  attr :page_title, :string, default: "Application SSO"
  slot :inner_block, required: true

  def docs_shell(assigns) do
    assigns = assign(assigns, :nav_sections, @nav_sections)

    ~H"""
    <div id="sso-docs" class="min-h-screen">
      <div
        id="docs-sidebar-backdrop"
        class="fixed inset-0 z-40 hidden bg-base-content/40 lg:hidden"
        aria-hidden="true"
      >
      </div>

      <aside
        id="docs-sidebar"
        class="fixed inset-y-0 left-0 z-50 flex w-72 -translate-x-full flex-col border-r border-base-300 bg-base-100 transition-transform duration-200 lg:translate-x-0"
      >
        <div class="flex items-center justify-between border-b border-base-300 px-5 py-4">
          <a href={~p"/"} class="text-sm font-semibold tracking-tight">AccountKit</a>
          <button
            type="button"
            id="docs-sidebar-close"
            class="btn btn-ghost btn-sm btn-square lg:hidden"
            aria-label="Close navigation"
          >
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="size-5">
              <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z" />
            </svg>
          </button>
        </div>

        <div class="border-b border-base-300 px-5 py-3">
          <p class="text-xs font-semibold uppercase tracking-wide text-base-content/50">Guides</p>
          <p class="mt-1 text-sm font-medium">{@page_title}</p>
        </div>

        <nav class="flex-1 overflow-y-auto px-3 py-4" aria-label="Documentation sections">
          <ul class="space-y-1">
            <li :for={section <- @nav_sections}>
              <a
                href={"##{section.id}"}
                data-docs-nav={section.id}
                class="docs-nav-link block rounded-lg px-3 py-2 text-sm text-base-content/70 transition hover:bg-base-200 hover:text-base-content"
              >
                {section.label}
              </a>
            </li>
          </ul>

          <div class="mt-6 border-t border-base-300 pt-4">
            <p class="px-3 text-xs font-semibold uppercase tracking-wide text-base-content/50">
              Reference
            </p>
            <a
              href={~p"/api/json/docs"}
              class="mt-2 block rounded-lg px-3 py-2 text-sm text-primary hover:bg-base-200"
            >
              OpenAPI docs
            </a>
          </div>
        </nav>
      </aside>

      <div class="lg:pl-72">
        <header class="sticky top-0 z-30 flex items-center gap-3 border-b border-base-300 bg-base-100/95 px-4 py-3 backdrop-blur lg:hidden">
          <button
            type="button"
            id="docs-sidebar-open"
            class="btn btn-ghost btn-sm btn-square"
            aria-label="Open navigation"
          >
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="size-5">
              <path
                fill-rule="evenodd"
                d="M2 4.75A.75.75 0 012.75 4h14.5a.75.75 0 010 1.5H2.75A.75.75 0 012 4.75zm0 5.25a.75.75 0 01.75-.75h14.5a.75.75 0 010 1.5H2.75A.75.75 0 012 10zm0 5.25a.75.75 0 01.75-.75h14.5a.75.75 0 010 1.5H2.75A.75.75 0 012 15.25z"
                clip-rule="evenodd"
              />
            </svg>
          </button>
          <span class="text-sm font-medium">Application SSO</span>
        </header>

        <main class="mx-auto max-w-3xl px-6 py-10 lg:px-10 lg:py-14">
          {render_slot(@inner_block)}
        </main>
      </div>
    </div>

    <script>
      (() => {
        const root = document.getElementById("sso-docs");
        if (!root) return;

        const sidebar = document.getElementById("docs-sidebar");
        const backdrop = document.getElementById("docs-sidebar-backdrop");
        const openBtn = document.getElementById("docs-sidebar-open");
        const closeBtn = document.getElementById("docs-sidebar-close");
        const navLinks = root.querySelectorAll("[data-docs-nav]");

        const openSidebar = () => {
          sidebar?.classList.remove("-translate-x-full");
          backdrop?.classList.remove("hidden");
        };

        const closeSidebar = () => {
          sidebar?.classList.add("-translate-x-full");
          backdrop?.classList.add("hidden");
        };

        openBtn?.addEventListener("click", openSidebar);
        closeBtn?.addEventListener("click", closeSidebar);
        backdrop?.addEventListener("click", closeSidebar);

        navLinks.forEach((link) => {
          link.addEventListener("click", () => {
            if (window.matchMedia("(max-width: 1023px)").matches) closeSidebar();
          });
        });

        const setActiveNav = () => {
          const hash = window.location.hash.replace("#", "") || "overview";
          navLinks.forEach((link) => {
            const active = link.getAttribute("data-docs-nav") === hash;
            link.classList.toggle("bg-base-200", active);
            link.classList.toggle("font-medium", active);
            link.classList.toggle("text-base-content", active);
            link.classList.toggle("text-base-content/70", !active);
          });
        };

        window.addEventListener("hashchange", setActiveNav);
        setActiveNav();
      })();
    </script>
    """
  end

  attr :id, :string, required: true
  attr :title, :string, required: true
  slot :inner_block, required: true

  def doc_section(assigns) do
    ~H"""
    <section id={@id} class="scroll-mt-24 border-b border-base-300 pb-12 last:border-b-0 last:pb-0">
      <h2 class="text-2xl font-bold tracking-tight">{@title}</h2>
      <div class="mt-4 space-y-4 text-base leading-7 text-base-content/80">
        {render_slot(@inner_block)}
      </div>
    </section>
    """
  end

  attr :language, :string, default: "text"
  attr :code, :string, required: true

  def code_block(assigns) do
    ~H"""
    <pre class="overflow-x-auto rounded-xl border border-base-300 bg-base-200/60 p-4 text-sm leading-6"><code class={"language-#{@language} font-mono text-[0.8125rem] text-base-content"}>{@code}</code></pre>
    """
  end
end
