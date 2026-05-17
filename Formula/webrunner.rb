class Webrunner < Formula
  desc "Zero-config development web server with CGI and .htaccess support"
  homepage "https://github.com/codedeviate/webrunner"
  url "https://github.com/codedeviate/webrunner/archive/refs/tags/v0.5.0.tar.gz"
  sha256 "1136129ba723bcfe0bc7786aa2e08bf75914a43d94e8b3f8235210c766572a6a"
  license "MIT"
  head "https://github.com/codedeviate/webrunner.git", branch: "master"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: ".")
  end

  test do
    assert_match "webrunner", shell_output("#{bin}/webrunner --version")
    assert_match "Development web server", shell_output("#{bin}/webrunner --help")

    port = free_port
    pid = spawn bin/"webrunner", "--port", port.to_s, "--no-index"
    begin
      sleep 2
      (testpath/"hello.txt").write "hi from webrunner"
      assert_match "hi from webrunner",
                   shell_output("curl --silent http://127.0.0.1:#{port}/hello.txt")
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
