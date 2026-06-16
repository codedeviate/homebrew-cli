# codedeviate/homebrew-cli

Homebrew tap for [codedeviate](https://github.com/codedeviate)'s Rust CLI tools.

## Usage

```bash
brew tap codedeviate/cli
brew install <formula>
```

Or in one shot, without an explicit `tap` step:

```bash
brew install codedeviate/cli/<formula>
```

## Available formulae

| Formula | Description |
| --- | --- |
| [`batty`](Formula/batty.rb) | Cat clone with syntax highlighting, git integration, and Rhai support |
| [`recon`](Formula/recon.rb) | Versatile network reconnaissance CLI: HTTP/TLS/DNS, multi-protocol probes, and a Rhai script engine |
| [`recon-impersonate`](Formula/recon-impersonate.rb) | `recon` with browser TLS+H2 fingerprint impersonation (BoringSSL via rquest) — conflicts with `recon` |
| [`sercon`](Formula/sercon.rb) | Embeddable TypeScript script engine CLI (pure Go, no Node) |
| [`sqlt`](Formula/sqlt.rb) | Multi-dialect SQL parser and translator (MySQL, MariaDB, PostgreSQL, MSSQL, SQLite) |
| [`tess`](Formula/tess.rb) | Less-style terminal pager with structured-log filtering and pretty-printing |
| [`webrunner`](Formula/webrunner.rb) | Zero-config development web server with CGI and .htaccess support |

`recon` and `recon-impersonate` both install a binary named `recon` and
therefore conflict — pick one:

```bash
brew install codedeviate/cli/recon              # lean build
brew install codedeviate/cli/recon-impersonate  # adds BoringSSL + cmake at build time
```

`witch` shares its name with the unrelated [`witch`](https://formulae.brew.sh/cask/witch)
cask (the manytricks window/tab switcher), so a bare `brew install witch` or
`brew upgrade witch` can resolve to the cask instead of this formula. Always use
the fully-qualified name:

```bash
brew install codedeviate/cli/witch
brew upgrade codedeviate/cli/witch
```

(A bare `brew upgrade` with no arguments still upgrades an already-installed
`codedeviate/cli/witch` correctly — the collision only bites explicit
`witch`-by-name commands.)

## Releasing a new version

For each formula, when the upstream project tags a new release:

```bash
./scripts/bump.sh <formula> <version>   # e.g. ./scripts/bump.sh tess 0.9.1
git diff Formula/<formula>.rb           # sanity check
git commit -am "<formula> <version>"
git push
```

`scripts/bump.sh`:

1. Verifies the upstream tarball at `https://github.com/codedeviate/<repo>/archive/refs/tags/v<version>.tar.gz` returns HTTP 200.
2. Computes the sha256 of that tarball.
3. `sed`-replaces `url` and `sha256` in `Formula/<formula>.rb`.

After bumping, smoke-test before announcing:

```bash
brew install --build-from-source codedeviate/cli/<formula>
brew test codedeviate/cli/<formula>
brew audit --strict codedeviate/cli/<formula>
```

## How installs work (and why nothing here is signed)

Every formula is a **source-build** formula. When you run
`brew install codedeviate/cli/<tool>` Homebrew does the following on
your machine:

1. Downloads the GitHub source tarball pinned by `url` + `sha256`.
2. Installs Rust as a build-only dependency (`depends_on "rust" => :build`).
3. Runs `cargo install` to compile the binary locally.
4. Removes Rust afterwards, since it is not a runtime dependency.

The resulting binary is built on your own Mac, so macOS never adds the
`com.apple.quarantine` attribute to it — Gatekeeper does not block it
and no Apple Developer ID signing or notarization is required. This is
deliberate: there are no pre-built bottles in this tap, no
`releases/download/<arch>.tar.gz` URLs, and no `bottle do` blocks
anywhere.

Trade-off: first install of each tool spends ~1–3 minutes compiling and
pulls down a few hundred MB of toolchain temporarily. If pre-built
bottles are added later, they would have to be signed and notarized to
clear Gatekeeper — that path is intentionally not taken here.

## Caveats

- `sha256` lines are placeholders until each upstream tag is reachable from a
  public GitHub repo. Until then, `brew install` will refuse to fetch the
  tarball, which is intentional.
- The CI workflow (`.github/workflows/tests.yml`) skips formulae whose
  `sha256` is still a placeholder, so `main` stays green pre-release.

## License

MIT — see [LICENSE](LICENSE).
