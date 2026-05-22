class Webrunner < Formula
  desc "Zero-config development web server with CGI and .htaccess support"
  homepage "https://github.com/codedeviate/webrunner"
  url "https://github.com/codedeviate/webrunner/archive/refs/tags/v0.8.1.tar.gz"
  sha256 "c6672f6188d3948f9b785b6cf526324faf17e6a86268f9de0022138845e962af"
  license "MIT"
  head "https://github.com/codedeviate/webrunner.git", branch: "master"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: ".")
    man1.install "man/webrunner.1"
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
