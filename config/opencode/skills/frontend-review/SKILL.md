# Frontend Review

## Purpose

Review frontend usability, accessibility and maintainability.

## When to use

- Reviewing React/Inertia/Laravel frontend changes.

## When not to use

- When the request needs production secrets.
- When scope and acceptance criteria are unclear.
- When a destructive action lacks explicit approval.

## Expected steps

1. Read project `AGENTS.md`, README and relevant specs.
2. Identify risk, dependencies and affected files.
3. Propose a minimal plan before changing code when non-trivial.
4. Execute only project-local changes.
5. Run relevant verification commands.
6. Summarize changed files, risks and rollback notes.

## Risks

- Hidden production credentials.
- Over-engineering.
- Framework version mismatch.
- Tool output trusted without review.

## Exit checklist

- [ ] Scope respected.
- [ ] No secrets added.
- [ ] Commands run or documented.
- [ ] Risks reported.
- [ ] Follow-up work listed.
