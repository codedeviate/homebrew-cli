class Batty < Formula
  desc "Cat clone with syntax highlighting, git integration, and Rhai support"
  homepage "https://github.com/codedeviate/batty"
  url "https://github.com/codedeviate/batty/archive/refs/tags/v0.13.1.tar.gz"
  sha256 "4470c7f4c13fdce680b0b22bae0d5414dbc6ff6859ac28e25ce305af4ae38a27"
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
