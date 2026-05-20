# AccountKit GOAL.md

## Product Vision

AccountKit is an open-source, self-hostable account infrastructure platform for modern SaaS applications.

It provides authentication, user management, multi-tenant account management, billing integration, API keys, admin dashboards, audit logs, and operational visibility in one Phoenix/Ash-based system.

AccountKit should feel like a serious developer product, not just an auth starter template. It should be easy to run locally, easy to self-host, pleasant to integrate, and solid enough to use in real production applications.

The main personal goal of this project is also to become deeply skilled in the Elixir ecosystem by building a real production-grade product with Phoenix, Ash, PostgreSQL, LiveView, Oban, and related BEAM tooling.

---

## One-Line Description

**AccountKit is an open-source account control center for auth, users, tenants, API keys, billing, and SaaS account management.**

---

## Product Positioning

AccountKit should not be marketed as “auth only.”

Better positioning:

- Open-source account infrastructure for SaaS apps
- Self-hosted Clerk-like account management with billing
- Auth, users, tenants, and billing for Phoenix/Ash apps
- Account control center for multi-tenant products
- Open-source user and billing foundation for SaaS builders

Avoid positioning it as:

- A generic SaaS boilerplate
- A full Clerk/Auth0 replacement on day one
- A payment starter only
- A full enterprise IAM system
- A complete authorization engine in the first version

---

## Target Stack

AccountKit will be built using the Elixir/Phoenix/Ash ecosystem.

Initial install command:

```bash
sh <(curl 'https://ash-hq.org/install/kit?install=phoenix') \
  && cd kit && mix igniter.install ash ash_phoenix \
  ash_json_api ash_postgres ash_authentication \
  ash_authentication_phoenix ash_admin ash_money \
  ash_double_entry ash_archival live_debugger \
  mishka_chelekom ash_paper_trail cinder \
  --auth-strategy password --auth-strategy magic_link \
  --auth-strategy api_key --setup --yes