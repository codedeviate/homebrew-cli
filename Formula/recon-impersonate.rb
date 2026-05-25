class ReconImpersonate < Formula
  desc "Recon with browser TLS+H2 fingerprint impersonation (BoringSSL via wreq)"
  homepage "https://github.com/codedeviate/recon"
  url "https://github.com/codedeviate/recon/archive/refs/tags/v0.90.0.tar.gz"
  sha256 "95fd9aba0163f6476511be7785350fc0c01365100c15c629302d696e3d9ba719"
  license "MIT"
  head "https://github.com/codedeviate/recon.git", branch: "master"

  depends_on "cmake" => :build # BoringSSL build prerequisite
  depends_on "rust" => :build

  # Both formulae install a binary named `recon` into HOMEBREW_PREFIX/bin.
  conflicts_with "recon",
    because: "both install the `recon` binary"

  def install
    system "cargo", "install",
           "--features", "impersonate",
           *std_cargo_args(path: ".")
  end

  test do
    assert_match "recon #{version}", shell_output("#{bin}/recon --version")
    assert_match "TLS-impersonation", shell_output("#{bin}/recon --version")
    assert_match "recon",
                 shell_output("#{bin}/recon --impersonate chrome_131 --version")
  end
end
