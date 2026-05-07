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
| [`sqlt`](Formula/sqlt.rb) | Multi-dialect SQL parser and translator (MySQL, MariaDB, PostgreSQL, MSSQL, SQLite) |
| [`tess`](Formula/tess.rb) | Less-style terminal pager with structured-log filtering and pretty-printing |
| [`webrunner`](Formula/webrunner.rb) | Zero-config development web server with CGI and .htaccess support |

`recon` and `recon-impersonate` both install a binary named `recon` and
therefore conflict — pick one:

```bash
brew install codedeviate/cli/recon              # lean build
brew install codedeviate/cli/recon-impersonate  # adds BoringSSL + cmake at build time
```

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

## Caveats

- Formulae build from source. Bottles are not produced yet — Rust builds can be
  slow on first install.
- `sha256` lines are placeholders until each upstream tag is reachable from a
  public GitHub repo. Until then, `brew install` will refuse to fetch the
  tarball, which is intentional.

## License

MIT — see [LICENSE](LICENSE).
