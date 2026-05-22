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

## Role Model

AccountKit uses scoped role assignments instead of a global `users.role` field.

- `platform_owner` is a global AccountKit operator role. It can manage the self-hosted AccountKit platform and cross-organization control-plane concerns.
- `org_admin` is scoped to one organization. It can manage that organization's apps, SSO/user-management settings, API keys, and later rate limits, without seeing or controlling other organizations.
- `end_user` is the future app-scoped identity for people who log into customer applications through AccountKit. End users should not automatically get access to the AccountKit dashboard.

Dashboard and control-plane access must be enforced server-side through authorization checks and route guards. UI links are convenience only and must never be the only access control.

The first `platform_owner` is bootstrapped only from an explicit configured email. AccountKit must not silently promote the first registered user.

`end_user` implementation is intentionally deferred until organizations, applications, and SSO flows are modeled together.

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