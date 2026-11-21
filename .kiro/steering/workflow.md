---
inclusion: always
---

# Team workflow

## Git and GitHub

- Never commit directly to `main`. Every change goes through a Pull Request reviewed by the other teammate.
- One branch per task, named after its module: `m3/nws-provider`, `m5/main-screen`, `m6/huayco-animation`.
- Commit messages follow Conventional Commits: `feat: add NWS provider`, `fix: map SENAMHI river levels by color`.
- **Do not run `git commit`, `git push` or open PRs unless a teammate explicitly asks.** Prepare the changes and
  suggest a commit message; the teammates commit and push themselves.
- Never add `.kiro/` or any of its subfolders to `.gitignore`: the hackathon requires it in the repository.
- `.env` is never committed. Document new variables in `.env.example` without real values.

## Modules and specs

- Work is split into modules M0–M8 (see `README.md`, section 11). Each module gets its own spec in
  `.kiro/specs/<module-folder>/`, for example `.kiro/specs/m3-providers/`.
- Write and review `requirements.md` and `design.md` before implementing `tasks.md`. Implement one task at a time.
- Respect module dependencies: M0 unlocks everything; M4 needs M2, M3a and the hazard slugs; Phase 2 (M6) starts only
  after Phase 1 works end to end with real data.
- Phase 1 UI stays simple: no Halloween styling until M6.

## Kiro usage log

- Record notable Kiro usage in `docs/bitacora-kiro.md`: specs created, hooks added, MCP servers used, property-based
  tests that caught bugs, and prompts or steering rules that made a difference. The hackathon write-up is built from it.
