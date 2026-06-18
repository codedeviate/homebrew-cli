class ReconImpersonate < Formula
  desc "Recon with browser TLS+H2 fingerprint impersonation (BoringSSL via wreq)"
  homepage "https://github.com/codedeviate/recon"
  url "https://github.com/codedeviate/recon/archive/refs/tags/v0.101.1.tar.gz"
  sha256 "4b598c0f659e28b15de8ca54032937fdce46c71c341e04ba8c0fff89c350f788"
  license "MIT"
  head "https://github.com/codedeviate/recon.git", branch: "master"

  depends_on "cmake" => :build # BoringSSL build prerequisite
  depends_on "rust" => :build

  # Both formulae install a binary named `recon` into HOMEBREW_PREFIX/bin.
  conflicts_with "recon",
    because: "both install the `recon` binary"

  def install
    # --no-default-features drops the `ssh` feature (libssh2/OpenSSL),
    # which collides with BoringSSL (wreq) at link time. See
    # https://github.com/codedeviate/recon/issues/1. This variant has
    # no scp/sftp/ssh support by design.
    system "cargo", "install",
           "--no-default-features",
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
