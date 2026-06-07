class Sercon < Formula
  desc "Reconnaissance, shaped by code — TypeScript script engine"
  homepage "https://github.com/codedeviate/sercon"
  url "https://github.com/codedeviate/sercon/archive/refs/tags/v0.39.0.tar.gz"
  sha256 "0ca53ed26ceb6e3875355cbc8b3c74ea498ee147e5a397e2ebf683dcd1b60d27"
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
