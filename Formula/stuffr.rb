class Stuffr < Formula
  desc "Universal compression and archive toolkit"
  homepage "https://github.com/codedeviate/stuffr"
  url "https://github.com/codedeviate/stuffr/archive/refs/tags/v0.5.0.tar.gz"
  sha256 "a8865b1c57ed0ce435e6814be0b941f0cf19d22e09355b5124e0768313c1cd43"
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

    # The legacy formats are in the DEFAULT build rather than behind
    # `--features legacy`. A bottle that silently lost them would install and
    # pass every assertion above, so these are the ones that would notice.
    # 0.4.2 added `arc` and `zoo`, bringing this to five.
    formats = shell_output("#{bin}/stuffr formats")
    assert_match "lha", formats
    assert_match "arj", formats
    assert_match "arc", formats
    assert_match "zoo", formats

    # Prove `.Z` decodes rather than merely registering. `compress` ships with
    # macOS, so the input is real rather than a fixture this formula carries.
    (testpath/"plain.txt").write "legacy\n"
    system "compress", "-f", testpath/"plain.txt"
    assert_equal "legacy\n", shell_output("#{bin}/stuffr cat plain.txt.Z")

    # 0.4.2's headline is the WRITE side: `.Z`, LHA and ARJ gained encoders,
    # so all three refused at exit 3 before this release and succeed after.
    # Asserting registration alone would not notice an encoder missing from a
    # bottle — this packs, then reads the archive back.
    system bin/"stuffr", "pack", testpath/"proj/a.txt", "-o", "out.lzh"
    assert_match "a.txt", shell_output("#{bin}/stuffr list out.lzh")

    # The `.Z` writer gets an EXTERNAL witness: macOS's own `uncompress` reads
    # what we wrote. That is a second implementation agreeing, not a round
    # trip through ourselves — the distinction this release was built on.
    system bin/"stuffr", "pack", testpath/"proj/a.txt", "-o", "witness.Z"
    system "uncompress", "-f", testpath/"witness.Z"
    assert_equal "alpha\n", (testpath/"witness").read

    # 0.5.0's headline: `stuffr salvage`, which recovers entries from archives
    # nothing else will open. Asserting the verb merely exists would pass on a
    # bottle that shipped it inert, so this destroys an archive and checks the
    # bytes come back.
    system bin/"stuffr", "pack", "proj", "-o", "full.zip"
    assert_match "proj/a.txt", shell_output("#{bin}/stuffr salvage --list full.zip")

    # Cut the tail off, taking the central directory with it. This is the
    # shape salvage exists for: the archive's own map to its contents is gone,
    # but every payload is still there behind a local header.
    whole = (testpath/"full.zip").binread
    (testpath/"cut.zip").binwrite(whole[0, whole.bytesize - 120])

    # Both the normal reader and the system tool give up here — that contrast
    # is the point, and it is what makes the recovery below meaningful rather
    # than a second way to do what `unpack` already does.
    assert_match "corrupt", shell_output("#{bin}/stuffr list cut.zip 2>&1", 5)
    assert_match "cannot find zipfile directory",
                 shell_output("unzip -l cut.zip 2>&1", 9)

    # salvage scans for the headers instead of trusting the index, and the
    # recovered bytes must be byte-identical to what went in.
    system bin/"stuffr", "salvage", "cut.zip", "-C", "rescued"
    assert_equal "alpha\n", (testpath/"rescued/proj/a.txt").read
    assert_equal "beta\n", (testpath/"rescued/proj/sub/b.bin").read
  end
end
