class Sercon < Formula
  desc "Embeddable TypeScript script engine CLI (pure Go, no Node)"
  homepage "https://github.com/codedeviate/sercon"
  url "https://github.com/codedeviate/sercon/archive/refs/tags/v0.6.0.tar.gz"
  sha256 "1c28e05fbcb94898cb1001aa7bdcbfca2ae5d3ba5c8cbff210f44c3c1ad7ac4b"
  license "MIT"
  head "https://github.com/codedeviate/sercon.git", branch: "master"

  depends_on "go" => :build

  def install
    system "go", "build", "-trimpath", "-ldflags", "-s -w",
           "-o", bin/"sercon", "./cmd/sercon"
  end

  test do
    assert_match "sercon v#{version}", shell_output("#{bin}/sercon --version")

    output = pipe_output("#{bin}/sercon -", "api.log(\"sum\", 1 + 1);")
    assert_match "sum 2", output
  end
end
