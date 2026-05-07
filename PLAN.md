# homebrew-cli — implementation plan

This is the design and rollout plan for the `codedeviate/homebrew-cli` tap. It
consolidates the five per-tool tap drafts that each repo's `BREW.md` referenced
(`homebrew-recon`, `homebrew-tess`, `homebrew-tap` for batty/sqlt/webrunner) into
a single tap, matching the layout sketched in `IDEA.md` and the repo list in
`DRAFT.md`.

## Goals

- One tap, one place, five tools.
- End-user install: `brew install codedeviate/cli/<tool>`.
- Source-build formulae (no bottles yet); same shape as the drafts already
  living in each tool repo.
- Per-release flow is `tag → release → bump tap formula` — no crates.io coupling
  and no auto-publishing wired up in this initial commit.

## Tap naming

| Property              | Value                                            |
| --------------------- | ------------------------------------------------ |
| GitHub repo           | `codedeviate/homebrew-cli`                       |
| Tap name              | `codedeviate/cli` (Homebrew strips `homebrew-`)  |
| Install command       | `brew install codedeviate/cli/<formula>`         |
| Tap command           | `brew tap codedeviate/cli`                       |

## Repository layout

```
homebrew-cli/
├── .github/
│   └── workflows/
│       └── tests.yml             # brew style + audit on PR / push
├── Formula/
│   ├── batty.rb
│   ├── recon.rb
│   ├── recon-impersonate.rb      # opt-in TLS impersonation variant; conflicts with recon.rb
│   ├── sqlt.rb
│   ├── tess.rb
│   └── webrunner.rb
├── scripts/
│   └── bump.sh                   # bump <tool> <version> — recomputes sha256, sed-replaces fields
├── DRAFT.md                      # original sketch (kept for context)
├── IDEA.md                       # original AI-generated draft (kept for context)
├── PLAN.md                       # this file
├── README.md                     # user-facing tap docs
├── LICENSE                       # MIT
└── .gitignore
```

## Formulae and current versions

Versions match each tool's `Cargo.toml` at the time this tap was scaffolded.
The `sha256` placeholder is intentional — it must be filled in *after* the
upstream tag is pushed and the repo is public, per each repo's `BREW.md`.

| Formula              | Version  | Source                                | Notes                                         |
| -------------------- | -------- | ------------------------------------- | --------------------------------------------- |
| `recon`              | 0.77.11  | `recon/homebrew/Formula/recon.rb`     | Lean build; `head` tracks `master`.           |
| `recon-impersonate`  | 0.77.11  | `recon/homebrew/Formula/recon-impersonate.rb` | Adds BoringSSL + `cmake`; conflicts with `recon`. |
| `batty`              | 0.9.0    | `homebrew-tap/Formula/batty.rb`       | `head` tracks `main`.                         |
| `tess`               | 0.9.0    | `homebrew-tess/Formula/tess.rb`       | Was at 0.6.6 in the local tap; bumped to match Cargo.toml. |
| `sqlt`               | 0.3.1    | `sqlt/Formula/sqlt.rb`                | Already release-shaped.                       |
| `webrunner`          | 0.1.0    | `webrunner/packaging/homebrew/webrunner.rb` | First release.                          |

## Per-release procedure

For any tool `<name>` cutting version `<X.Y.Z>`:

1. **In the tool repo:** bump `Cargo.toml`, commit, tag `v<X.Y.Z>`, push tag.
2. **(Optional) Create a GitHub release** so users see notes; the tap formula
   pulls the auto-generated source tarball regardless.
3. **In this tap:**

   ```sh
   ./scripts/bump.sh <name> <X.Y.Z>
   git diff Formula/<name>.rb        # sanity check
   git commit -am "<name> <X.Y.Z>"
   git push
   ```

   `scripts/bump.sh` verifies the tarball URL returns HTTP 200, computes the
   sha256, and `sed`-rewrites `url` + `sha256` in the formula. It mirrors the
   per-repo bump scripts that already existed for tess and (manually) for the
   others.
4. **Smoke test before announcing:**

   ```sh
   brew tap codedeviate/cli
   brew install --build-from-source codedeviate/cli/<name>
   brew test codedeviate/cli/<name>
   brew audit --strict codedeviate/cli/<name>
   ```

## CI

`.github/workflows/tests.yml` runs on `push` to `main` and on every PR:

- Sets up Homebrew (`Homebrew/actions/setup-homebrew@master`).
- Runs `brew style Formula/*.rb`.
- Runs `brew audit --strict Formula/*.rb` (no `--online` until upstream repos
  are public — flip the flag once they are).

A separate `update-formula.yml` workflow that fires on `repository_dispatch`
from each tool repo is **out of scope for this initial commit**. Each tool's
`BREW.md` keeps the manual `bump.sh` flow as the documented path; we can wire
automated dispatches later once the manual flow is proven.

## What this commit deliberately does not do

Per the user's instruction:

- **No crates.io interaction.** `cargo publish` is independent and stays in
  each tool repo's release runbook.
- **No `brew tap` / `brew install` on the user's machine.**
- **No upstream tag creation, no `gh release create`, no SSH key changes.**
- **No retiring the older per-tool tap repos** (`homebrew-tap`, `homebrew-tess`).
  Once this tap is announced, the user can archive those by hand.

Everything is staged and pushable; the `sha256` placeholders block accidental
installs of the unreleased combinations until the user explicitly bumps each
formula.
