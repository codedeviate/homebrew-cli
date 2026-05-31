class Sercon < Formula
  desc "Embeddable TypeScript script engine CLI (pure Go, no Node)"
  homepage "https://github.com/codedeviate/sercon"
  url "https://github.com/codedeviate/sercon/archive/refs/tags/v0.26.0.tar.gz"
  sha256 "e6ce52250133400899f3289f40a7ddad4dd7c5b20fe3549f9cb975d681a0d098"
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
