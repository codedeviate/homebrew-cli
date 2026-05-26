class Sercon < Formula
  desc "Embeddable TypeScript script engine CLI (pure Go, no Node)"
  homepage "https://github.com/codedeviate/sercon"
  url "https://github.com/codedeviate/sercon/archive/refs/tags/v0.5.30.tar.gz"
  sha256 "1a5411672ae4cad1758c387a85f36f0e6108f8e776378baf7f529d3ce2a28340"
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
