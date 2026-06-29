# MCP Security

MCP servers run with local process permissions. Treat every MCP as delegated local access for an agent.

## v1 allowed MCPs

- filesystem: allowed only for scoped workspace/project paths by default.
- playwright: allowed for local UI testing and browser automation.
- context7: allowed for documentation lookup.
- postgres: allowed only with development credentials.

## Explicitly rejected

- shell MCP is not part of v1.
- Production database credentials are not allowed.
- Whole-HOME filesystem access is disabled unless explicitly approved with `MCP_FILESYSTEM_ALLOW_HOME="true"` and the confirmation gate.

## Browser sessions

Do not expose personal or production browser sessions to Playwright MCP without a written reason. Prefer isolated local test profiles.
