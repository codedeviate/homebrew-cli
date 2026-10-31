class Targrep < Formula
  desc "Search log archives (tar, zip; gzip, zstd, xz, bzip2, lz4, .Z) with rg flags"
  homepage "https://github.com/codedeviate/trg"
  url "https://github.com/codedeviate/trg/archive/refs/tags/v0.12.0.tar.gz"
  sha256 "3546a1a38bd1fe9a4d3641061ccd40a43548ff8f6eb20c172ffbf689cf6d25fb"
  license "MIT"
  head "https://github.com/codedeviate/trg.git", branch: "master"

  depends_on "cmake" => :build
  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: ".")
  end

  test do
    assert_match "trg #{version}", shell_output("#{bin}/trg --version")

    (testpath/"logs/app.log").write "boot ok\nneedle in a haystack\nshutdown\n"
    system "tar", "-czf", testpath/"logs.tgz", "-C", testpath, "logs"

    assert_match "needle in a haystack", shell_output("#{bin}/trg needle #{testpath}/logs.tgz")

    system "tar", "-cJf", testpath/"logs.tar.xz", "-C", testpath, "logs"
    assert_match "needle in a haystack", shell_output("#{bin}/trg needle #{testpath}/logs.tar.xz")

    system "tar", "-cjf", testpath/"logs.tar.bz2", "-C", testpath, "logs"
    assert_match "needle in a haystack", shell_output("#{bin}/trg needle #{testpath}/logs.tar.bz2")

    system "zip", "-q", "-r", testpath/"logs.zip", "logs"
    assert_match "logs/app.log:2:needle", shell_output("#{bin}/trg needle #{testpath}/logs.zip")
  end
end
