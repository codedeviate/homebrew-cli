class Sercon < Formula
  desc "Reconnaissance, shaped by code — TypeScript script engine"
  homepage "https://github.com/codedeviate/sercon"
  url "https://github.com/codedeviate/sercon/archive/refs/tags/v0.90.2.tar.gz"
  sha256 "6824387bd1c6e3dd88ff66809dcf92e422c607679791053335ec6b7d2a7a7c1e"
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
