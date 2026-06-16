class Tess < Formula
  desc "Less-style terminal pager with structured-log filtering and pretty-printing"
  homepage "https://github.com/codedeviate/tess"
  url "https://github.com/codedeviate/tess/archive/refs/tags/v0.37.0.tar.gz"
  sha256 "81fddda4d882576d5a9c69f29bfa76c914a3e9aa71eb098794e7a99d4a98a3d9"
  license "MIT"
  head "https://github.com/codedeviate/tess.git", branch: "master"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: ".")
    man1.install "man/tess.1" if (buildpath/"man/tess.1").exist?
  end

  test do
    assert_match "tess #{version}", shell_output("#{bin}/tess --version")
    assert_match "apache-combined", shell_output("#{bin}/tess --list-formats")
  end
end
