class Recon < Formula
  desc "Network reconnaissance CLI with HTTP/TLS/DNS probes and Rhai scripting"
  homepage "https://github.com/codedeviate/recon"
  url "https://github.com/codedeviate/recon/archive/refs/tags/v0.98.0.tar.gz"
  sha256 "8dda54785e8e36756e3b75d6d2ab0cde5820369a5e60ad16fd982bc13d161ddd"
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
