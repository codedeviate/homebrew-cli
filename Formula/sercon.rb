class Sercon < Formula
  desc "Embeddable TypeScript script engine CLI (pure Go, no Node)"
  homepage "https://github.com/codedeviate/sercon"
  url "https://github.com/codedeviate/sercon/archive/refs/tags/v0.9.0.tar.gz"
  sha256 "18ec70e649de0a3fc209c00f4843e696de91cb8755ea167d193f890e3f5f3685"
  license "MIT"
  head "https://github.com/codedeviate/sercon.git", branch: "master"

  depends_on "go" => :build

  def install
    system "go", "build", "-trimpath", "-ldflags", "-s -w",
           "-o", bin/"sercon", "./cmd/sercon"
  end

  test do
    assert_match "sercon v#{version}", shell_output("#{bin}/sercon --version")

    output = pipe_output("#{bin}/sercon -", "runtime.log(\"sum\", 1 + 1);")
    assert_match "sum 2", output
  end
end
