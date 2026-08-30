class Stere < Formula
  desc "Structure-aware, searchable archive format for log files"
  homepage "https://github.com/codedeviate/stere"
  url "https://github.com/codedeviate/stere/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "5ffbd4e7e5eb7187da84b29e171b14bef9874337400b9bc0a1be87c57b6290a4"
  license "MIT"
  head "https://github.com/codedeviate/stere.git", branch: "main"

  depends_on "rust" => :build

  def install
    # Cargo workspace: the binary lives in crates/stere, so the virtual root
    # manifest cannot be installed directly (`cargo install` refuses a path
    # with multiple packages).
    system "cargo", "install", *std_cargo_args(path: "crates/stere")
  end

  test do
    (testpath/"app.log").write <<~LOG
      2026-08-30T10:00:01 INFO  worker=1 request completed in 1ms
      2026-08-30T10:00:02 INFO  worker=2 request completed in 2ms
      2026-08-30T10:00:03 ERROR worker=3 upstream timeout
    LOG

    system bin/"stere", "archive", "app.stere", "app.log"
    assert_path_exists testpath/"app.stere"

    assert_match "app.log", shell_output("#{bin}/stere list app.stere")
    assert_match "ok:", shell_output("#{bin}/stere verify app.stere")

    # Streaming the archive back reproduces the input byte for byte.
    expected = (testpath/"app.log").read
    assert_equal expected, shell_output("#{bin}/stere cat app.stere")

    # Searching does not require a full decompress.
    assert_match "upstream timeout",
                 shell_output("#{bin}/stere grep 'upstream timeout' app.stere")

    assert_match "stere #{version}", shell_output("#{bin}/stere --version")
  end
end
