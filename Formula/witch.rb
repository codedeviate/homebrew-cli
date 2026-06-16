class Witch < Formula
  desc "Typo-tolerant which that finds PATH commands even when misspelled"
  homepage "https://github.com/codedeviate/witch"
  url "https://github.com/codedeviate/witch/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "af8a7a8abd7af255e520ed50ffb61220fae5b528f995cb078b301bf0cc4e1433"
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
