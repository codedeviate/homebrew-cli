class Targrep < Formula
  desc "Search log archives (tar, zip; gzip, zstd, xz, bzip2, lz4, .Z) with rg flags"
  homepage "https://github.com/codedeviate/trg"
  url "https://github.com/codedeviate/trg/archive/refs/tags/v0.13.0.tar.gz"
  sha256 "4f4da8d9964138449f111cf9dd99c92eb53d06da055a0aca9728f0e7c75f3a4e"
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
