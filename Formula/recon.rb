class Recon < Formula
  desc "Network reconnaissance CLI with HTTP/TLS/DNS probes and Rhai scripting"
  homepage "https://github.com/codedeviate/recon"
  url "https://github.com/codedeviate/recon/archive/refs/tags/v0.92.1.tar.gz"
  sha256 "3dc62fb3f86d7b834e2fed5f3f0934e87d6ddc09b24aa6967ca97e63ea6139e2"
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
