class Stere < Formula
  desc "Structure-aware, searchable archive format for log files"
  homepage "https://github.com/codedeviate/stere"
  url "https://github.com/codedeviate/stere/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "27a790616a1700572ef3546e3913a3b022761eefc0628c5dca700f942b9dc72a"
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
