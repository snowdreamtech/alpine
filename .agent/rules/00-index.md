# 🚦 Project Rule Index (Lazy Loading Router)

## 🚨 CRITICAL INSTRUCTION FOR ALL AI AGENTS 🚨

To prevent token limit overflow and context pollution, **DO NOT load all files** in the `.agent/rules/` directory simultaneously.

You MUST follow this strict loading protocol:

1. **Always Load Core Fundamentals (01-12)**:
   - These files contain the universal constraints that apply to *everything*.
   - You must implicitly understand or load `01-general.md` through `12-docs.md`.

2. **Lazy-Load Specialized Rules ON DEMAND**:
   - Only load technology-specific or domain-specific rules (`*.md` files below) **IF** the current task strictly requires them.
   - For example, if you are working on a React frontend, do NOT load backend rules (like `go.md` or `python.md`).
   - Use the alphabetical index below to locate the specific file you need, and load it via your `view_file` or equivalent reading tool.

---

## Language & Framework Index (A-Z)

| Technology | Rule File |
| :--- | :--- |
| **A** | `accessibility.md`, `actix-web.md`, `angular.md`, `ansible.md`, `api-design.md`, `astro.md`, `axum.md` |
| **B** | `beego.md`, `bun.md` |
| **C** | `c.md`, `chi.md`, `cpp.md`, `csharp.md`, `css.md` |
| **D** | `data-engineering.md`, `deno.md`, `django.md`, `docker.md` |
| **E** | `echo.md`, `elasticsearch.md`, `elixir.md`, `express.md` |
| **F** | `fastapi.md`, `fiber.md`, `flask.md`, `flutter.md` |
| **G** | `gin.md`, `github-actions.md`, `go-zero.md`, `go.md`, `gorm.md`, `graphql.md`, `grpc.md` |
| **H** | `hono.md`, `html.md` |
| **I/J/K** | `java.md`, `javascript.md`, `kotlin.md`, `kratos.md`, `kubernetes.md` |
| **L/M** | `laravel.md`, `llm-prompt.md`, `lua.md`, `markdown.md`, `mongodb.md`, `monitoring.md`, `mysql.md` |
| **N/O/P** | `nestjs.md`, `nextjs.md`, `node.md`, `nuxt.md`, `php.md`, `postgresql.md`, `prisma.md`, `python.md` |
| **Q/R** | `r.md`, `rails.md`, `react.md`, `redis.md`, `remix.md`, `ruby.md`, `rust.md` |
| **S** | `scala.md`, `shell.md`, `spring.md`, `sql.md`, `sqlalchemy.md`, `svelte.md`, `swift.md` |
| **T/U/V** | `terraform.md`, `trpc.md`, `typescript.md`, `vue.md` |
| **W/X/Y/Z** | `wasm.md`, `yaml.md` |

---

> By adhering to this Lazy Loading strategy, you ensure blazing-fast performance, zero context hallucination, and flawless compliance with the specific domain you are operating in.
