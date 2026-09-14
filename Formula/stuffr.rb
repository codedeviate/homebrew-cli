class Stuffr < Formula
  desc "Universal compression and archive toolkit"
  homepage "https://github.com/codedeviate/stuffr"
  url "https://github.com/codedeviate/stuffr/archive/refs/tags/v0.4.0.tar.gz"
  sha256 "01d353c660adb53590aa209c9137ec7dc47a49db501d4da1c2219a04204f2b5d"
  license "MIT"
  head "https://github.com/codedeviate/stuffr.git", branch: "main"

  depends_on "rust" => :build

  def install
    # Cargo workspace: the binary lives in crates/stuffr-cli (the `stuffr`
    # crate is the library facade), so the virtual root manifest cannot be
    # installed directly — `cargo install` refuses a path with multiple
    # packages. This is also why the crates.io spelling is
    # `cargo install stuffr-cli` rather than `cargo install stuffr`.
    system "cargo", "install", *std_cargo_args(path: "crates/stuffr-cli")
  end

  test do
    # A tree with the three shapes that behave differently: a nested file,
    # an empty directory, and a symlink.
    (testpath/"proj/sub").mkpath
    (testpath/"proj/empty").mkpath
    (testpath/"proj/a.txt").write "alpha\n"
    (testpath/"proj/sub/b.bin").write "beta\n"
    ln_s "a.txt", testpath/"proj/link"

    # The headline: walk a directory AND compose a container over a codec in
    # one step. Both halves were missing before 0.3.0.
    system bin/"stuffr", "pack", "proj", "-o", "backup.tar.gz"
    assert_path_exists testpath/"backup.tar.gz"

    # It really is gzip, and really is a tar inside — 0.2.0 wrote one or the
    # other and never both.
    assert_match "proj/a.txt", shell_output("#{bin}/stuffr list backup.tar.gz")
    system "tar", "tzf", "backup.tar.gz"

    # Round trip restores the tree, including the shapes a lesser writer drops.
    system bin/"stuffr", "unpack", "backup.tar.gz", "-C", "back"
    assert_equal "alpha\n", (testpath/"back/proj/a.txt").read
    assert_equal "beta\n", (testpath/"back/proj/sub/b.bin").read
    assert_predicate testpath/"back/proj/empty", :directory?
    assert_equal "a.txt", File.readlink(testpath/"back/proj/link")

    # Entries are reachable by position, which is how you disambiguate names
    # that collide on a case-insensitive filesystem.
    assert_equal "alpha\n", shell_output("#{bin}/stuffr cat backup.tar.gz --index 1")

    # 0.4.0's headline: three read-only legacy formats, and they are in the
    # DEFAULT build rather than behind `--features legacy`. A bottle that
    # silently lost them would install and pass every assertion above, so
    # this is the one that would notice.
    assert_match "lha", shell_output("#{bin}/stuffr formats")
    assert_match "arj", shell_output("#{bin}/stuffr formats")

    # And prove one of them actually decodes rather than merely registering.
    # `compress` ships with macOS, so the input is real rather than a fixture
    # this formula would have to carry.
    (testpath/"plain.txt").write "legacy\n"
    system "compress", "-f", testpath/"plain.txt"
    assert_equal "legacy\n", shell_output("#{bin}/stuffr cat plain.txt.Z")
  end
end
