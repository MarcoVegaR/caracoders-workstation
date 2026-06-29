# Host vs container matrix

| Tool | Placement | Reason |
|---|---:|---|
| PHP | ambos | Host CLI; project runtime in container |
| Composer | ambos | Host convenience; project dependency install |
| Laravel Installer | host | Project creation convenience |
| Node | ambos | Host NVM; project fixed in container |
| npm | ambos | Host tooling; project scripts |
| pnpm | ambos | Host convenience; project scripts |
| PostgreSQL Server | container | No global DB server |
| PostgreSQL client | host | psql inspection |
| pgAdmin | container | Web GUI local container |
| Redis | container | Project-local runtime |
| Mailpit | container | Project-local mail capture |
| VS Code | host | Editor/client |
| OpenCode | host | Primary agent interface |
| MCP filesystem | host | Scoped agent tool |
| MCP postgres | host | Dev DB only |
| Playwright MCP | host | Local browser automation |
| Docker | host | Engine |
| Docker Compose | host | Orchestration |
| Dev Containers | ambos | Host client, container runtime |
| Gitleaks | host/CI | CI mandatory |
| Trivy | host/CI | CI scanner |
| Hadolint | host/CI | Dockerfile lint |
| ShellCheck | host/CI | Bash lint |
