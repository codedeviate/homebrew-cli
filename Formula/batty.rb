class Batty < Formula
  desc "Cat clone with syntax highlighting, git integration, and Rhai support"
  homepage "https://github.com/codedeviate/batty"
  url "https://github.com/codedeviate/batty/archive/refs/tags/v0.12.0.tar.gz"
  sha256 "3fd00c3f3b57a8e69ad503f550af8610b27bdd7dfc3105be5f6912695dc41954"
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
