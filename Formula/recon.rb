class Recon < Formula
  desc "Network reconnaissance CLI with HTTP/TLS/DNS probes and Rhai scripting"
  homepage "https://github.com/codedeviate/recon"
  url "https://github.com/codedeviate/recon/archive/refs/tags/v0.101.0.tar.gz"
  sha256 "302c79938509790a6f05f9cf7946322cdf443dfe2893c6f9b67e373e7c2da5f0"
  license "MIT"
  head "https://github.com/codedeviate/recon.git", branch: "master"

  depends_on "rust" => :build

  # Both formulae install a binary named `recon` into HOMEBREW_PREFIX/bin.
  conflicts_with "recon-impersonate",
    because: "both install the `recon` binary"

  def install
    system "cargo", "install", *std_cargo_args(path: ".")
  end

  test do
    assert_match "recon #{version}", shell_output("#{bin}/recon --version")
    assert_match "--header", shell_output("#{bin}/recon --flags")
  end
end
