class Sercon < Formula
  desc "Reconnaissance, shaped by code — TypeScript script engine"
  homepage "https://github.com/codedeviate/sercon"
  url "https://github.com/codedeviate/sercon/archive/refs/tags/v0.60.0.tar.gz"
  sha256 "a1db423ebe2064d51ad46e44800ce22ffd58eceaeab74623b25296fd06c2ea70"
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
