A clean modern setup is usually:

```text
homebrew-cli/
├── .github/
│   └── workflows/
│       ├── tests.yml
│       └── update-formula.yml
├── Formula/
│   ├── recon.rb
│   ├── batty.rb
│   ├── webrunner.rb
│   ├── sqlt.rb
│   └── tess.rb
├── README.md
└── LICENSE
```

The repository name should ideally follow Homebrew conventions:

```text
homebrew-cli
```

which becomes the tap:

```text
codedv8/cli
```

---

# Formula layout

Example:

```ruby
class Recon < Formula
  desc "Recon CLI utility"
  homepage "https://github.com/codedv8/recon"
  url "https://github.com/codedv8/recon/archive/refs/tags/v1.2.3.tar.gz"
  sha256 "..."
  license "MIT"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/recon --version")
  end
end
```

You repeat that pattern for each tool.

---

# Recommended release model

The cleanest setup is:

- One repo per tool
  - `codedv8/recon`
  - `codedv8/batty`
  - etc.

- One dedicated tap repo
  - `codedv8/homebrew-cli`

Each tool publishes GitHub releases.

The tap repo only contains formulae.

This scales much better than embedding formulae inside each project repo.

---

# Minimal CI: Formula validation

`.github/workflows/tests.yml`

```yaml
name: Test Formulae

on:
  pull_request:
  push:
    branches:
      - main

jobs:
  test:
    runs-on: macos-latest

    steps:
      - uses: actions/checkout@v4

      - name: Set up Homebrew
        uses: Homebrew/actions/setup-homebrew@master

      - name: Audit formulae
        run: |
          brew audit --strict --online Formula/*.rb

      - name: Test install
        run: |
          brew install --build-from-source ./Formula/recon.rb
          brew install --build-from-source ./Formula/batty.rb
```

This verifies:

- syntax
- style
- installability
- dependencies

---

# Auto-update formulae

The usual pattern is:

1. Tool repo creates release
2. GitHub Action updates formula in tap repo
3. Commit + push updated version/SHA

There are two common approaches:

## Option A — Use Homebrew tools (`brew bump-formula-pr`)

Good for public/open workflows.

## Option B — Simple sed/script replacement

Usually easier for personal taps.

For your case, Option B is likely better.

---

# Example auto-update workflow

Inside tool repo (`recon`):

`.github/workflows/release.yml`

```yaml
name: Release

on:
  release:
    types: [published]

jobs:
  update-homebrew:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout tap repo
        uses: actions/checkout@v4
        with:
          repository: codedv8/homebrew-cli
          token: ${{ secrets.HOMEBREW_TAP_TOKEN }}
          path: tap

      - name: Download release tarball
        run: |
          curl -L \
            -o source.tar.gz \
            ${{ github.event.release.tarball_url }}

      - name: Calculate SHA256
        id: sha
        run: |
          echo "sha=$(sha256sum source.tar.gz | cut -d' ' -f1)" >> $GITHUB_OUTPUT

      - name: Update formula
        run: |
          cd tap

          sed -i \
            's|url ".*"|url "${{ github.event.release.tarball_url }}"|' \
            Formula/recon.rb

          sed -i \
            's|sha256 ".*"|sha256 "${{ steps.sha.outputs.sha }}"|' \
            Formula/recon.rb

      - name: Commit changes
        run: |
          cd tap

          git config user.name github-actions
          git config user.email github-actions@github.com

          git add Formula/recon.rb
          git commit -m "recon ${{ github.event.release.tag_name }}"
          git push
```

---

# Better approach for compiled binaries

If your tools are Rust/Go/Zig/etc., you probably want:

```ruby
bottle do
```

or downloadable precompiled binaries.

Otherwise users compile from source every install.

For Rust tools especially:

- compiling can be slow
- users may need Rust installed

A better formula is often:

```ruby
url "https://github.com/codedv8/recon/releases/download/v1.2.3/recon-aarch64-apple-darwin.tar.gz"
```

instead of source tarballs.

Then `install` simply copies binaries:

```ruby
def install
  bin.install "recon"
end
```

This gives:

- faster installs
- no build dependencies
- cleaner UX

---

# Recommended architecture for your ecosystem

Given your tool names, I’d structure it like:

```text
codedv8/
├── recon
├── batty
├── webrunner
├── sqlt
├── tess
└── homebrew-cli
```

Each tool:

- independent releases
- own CI
- own README/docs

Tap repo:

- only formulae
- lightweight CI
- auto-updated by releases

That’s the model many mature CLI ecosystems use.
