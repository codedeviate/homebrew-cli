class Recon < Formula
  desc "Network reconnaissance CLI with HTTP/TLS/DNS probes and Rhai scripting"
  homepage "https://github.com/codedeviate/recon"
  url "https://github.com/codedeviate/recon/archive/refs/tags/v0.101.1.tar.gz"
  sha256 "4b598c0f659e28b15de8ca54032937fdce46c71c341e04ba8c0fff89c350f788"
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
