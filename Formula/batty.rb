class Batty < Formula
  desc "Cat clone with syntax highlighting, git integration, and Rhai support"
  homepage "https://github.com/codedeviate/batty"
  url "https://github.com/codedeviate/batty/archive/refs/tags/v0.10.0.tar.gz"
  sha256 "8366774740fa8da806a808777812adf67bad4d6b0ba9562dc7cebd40b8305e51"
  license "MIT"
  head "https://github.com/codedeviate/batty.git", branch: "main"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: ".")
    man1.install "man/batty.1"
  end

  test do
    (testpath/"hello.rs").write <<~RUST
      fn main() {
          println!("hello, world");
      }
    RUST

    output = shell_output("#{bin}/batty --plain --paging=never --color=never #{testpath}/hello.rs")
    assert_match "println!", output

    assert_match "batty #{version}", shell_output("#{bin}/batty --version")
  end
end
