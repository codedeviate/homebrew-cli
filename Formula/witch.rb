class Witch < Formula
  desc "Typo-tolerant which that finds PATH commands even when misspelled"
  homepage "https://github.com/codedeviate/witch"
  url "https://github.com/codedeviate/witch/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "a9c0a33ee7644beb2920e664383de0091faeb1e762e160e2ef857e78e74e6dd8"
  license "MIT"
  head "https://github.com/codedeviate/witch.git", branch: "master"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: ".")
  end

  test do
    assert_match "witch #{version}", shell_output("#{bin}/witch --version")

    (testpath/"frobnicate").write "#!/bin/sh\necho ok\n"
    chmod 0755, testpath/"frobnicate"
    ENV.prepend_path "PATH", testpath

    # exact lookup behaves like `which`
    assert_match "frobnicate", shell_output("#{bin}/witch frobnicate")

    # typo-tolerant lookup still resolves to the real binary
    assert_match "frobnicate", shell_output("#{bin}/witch -1 frobnicat")
  end
end
