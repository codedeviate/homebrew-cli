class Stuffr < Formula
  desc "Universal compression and archive toolkit"
  homepage "https://github.com/codedeviate/stuffr"
  url "https://github.com/codedeviate/stuffr/archive/refs/tags/v0.18.2.tar.gz"
  sha256 "4a20b182acf0466ad21223f295890a1ce431e15813382315f6acae07e06930d2"
  # stuffr-cli carries code ported from bzip2 1.0.8 (crates/stuffr-cli/LICENSE-bzip2)
  # and from Apple's BSD-licensed gzip sources (crates/stuffr-cli/LICENSE-gzip-bsd);
  # stuffr-formats' pack decoder is BSD-2-Clause (crates/stuffr-formats/LICENSE-unpack-bsd);
  # the xz family is ported from XZ Utils 5.8.4 under 0BSD (crates/stuffr-cli/LICENSE-xz,
  # crates/stuffr-formats/LICENSE-xz-memusage); the zstd family is ported from zstd 1.5.7
  # under BSD-3-Clause (crates/stuffr-cli/LICENSE-zstd), and this build links libzstd;
  # the lz4 family is a clean-room implementation (lz4's GPL command line tool was not
  # read) and this build links liblz4 1.10.0, BSD-2-Clause (crates/stuffr-cli/LICENSE-lz4).
  license all_of: ["MIT", "bzip2-1.0.6", "BSD-2-Clause", "BSD-3-Clause", "0BSD"]
  head "https://github.com/codedeviate/stuffr.git", branch: "main"

  depends_on "rust" => :build

  def install
    # Cargo workspace: the binary lives in crates/stuffr-cli (the `stuffr`
    # crate is the library facade), so the virtual root manifest cannot be
    # installed directly — `cargo install` refuses a path with multiple
    # packages. This is also why the crates.io spelling is
    # `cargo install stuffr-cli` rather than `cargo install stuffr`.
    #
    # `zstd-c` builds libzstd 1.5.7 in (vendored by zstd-sys, pinned by the
    # lock file that std_cargo_args' `--locked` honours), so the zstd links
    # write zstd's exact bytes and support dictionaries and --train.
    # `lz4-c` does the same for liblz4 1.10.0 (vendored by lz4-sys), so the
    # lz4 links write lz4's exact bytes at every level.
    system "cargo", "install", *std_cargo_args(path: "crates/stuffr-cli", features: ["zstd-c", "lz4-c"])
  end

  def caveats
    <<~EOS
      stuffr can stand in for bzip2, bunzip2, bzcat and bzip2recover (bzip2
      1.0.8 behaviour, byte-identical output) and for gzip, gunzip, zcat and
      gzcat (Apple's gzip behaviour on macOS; STUFFR_GZIP_FLAVOR=gnu switches
      to GNU gzip's), and for xz, unxz, xzcat, lzma, unlzma and lzcat (XZ
      Utils 5.8.4 behaviour), and for zstd, unzstd, zstdcat and zstdmt (zstd
      1.5.7 behaviour; this build's zstd output is byte-identical to zstd's),
      and for lz4, unlz4, lz4cat and lz4c (lz4 1.10.0 behaviour; this build's
      lz4 output is byte-identical to lz4's), and for unzip, zipinfo and
      funzip (Info-ZIP UnZip 6.0: Apple's build on macOS;
      STUFFR_UNZIP_FLAVOR=ubuntu switches to Ubuntu's 6.0-28ubuntu4.1).
      This build's gzip and xz output is compatible with the real tools', not
      byte-identical: identical bytes need the C tier (--features c-backed).
      The links are opt-in:

        mkdir -p ~/.local/bin
        stuffr install-links --dir ~/.local/bin

      Put that directory ahead of /usr/bin on PATH to use them. The links point
      at #{opt_bin}/stuffr, so they survive `brew upgrade`;
      `stuffr install-links --dir DIR --remove` takes them away again.
    EOS
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

    # 0.17.0: `stuffr bench` times every writable codec on the user's own
    # files. A release build is the only kind that times (a debug build
    # refuses), so the installed binary must produce a row per codec.
    (testpath/"bench.txt").write "GET /index.html HTTP/1.1 200 1043\n" * 2000
    table = shell_output("#{bin}/stuffr bench --table-only #{testpath}/bench.txt")
    assert_match "gzip", table
    assert_match "xz", table
    assert_match "zstd", table
    # 0.18.1: each row also reports its peak compress and decompress memory.
    assert_match "c-mem", table
    assert_match "d-mem", table

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

    # Salvage Stage 2's headline: salvage reaches four more formats — arc,
    # zoo, lha and arj — where 0.5.0 knew only zip. That capability is
    # 0.6.0's, but 0.6.0 was tagged and never published (a deep fuzz run
    # against the tag found four exit-code defects), so 0.6.1 is the first
    # release anyone can install it from. LHA is the one a bottle can prove
    # end to end, because stuffr can both WRITE it (0.4.2) and salvage it;
    # nothing on a clean macOS box creates an .lzh, so the alternative is a
    # carried fixture, which proves less than a round trip through our own
    # writer and a scanner that never consults it.
    system bin/"stuffr", "pack", "proj", "-o", "legacy.lzh"
    assert_match "proj/a.txt", shell_output("#{bin}/stuffr salvage --list legacy.lzh")

    # Cut the tail off. The ordinary reader refuses the archive; salvage walks
    # the headers it can still see and returns what survived. Asserting the
    # verb merely accepts `--format lha` would pass on a bottle that shipped
    # the scanner inert, so this destroys an archive and reads the bytes back.
    whole_lzh = (testpath/"legacy.lzh").binread
    (testpath/"cut.lzh").binwrite(whole_lzh[0, whole_lzh.bytesize - 40])
    assert_match "corrupt", shell_output("#{bin}/stuffr list cut.lzh 2>&1", 5)

    system bin/"stuffr", "salvage", "cut.lzh", "-C", "lharescue"
    assert_equal "alpha\n", (testpath/"lharescue/proj/a.txt").read

    # 0.11.0's headline: compatibility links. Make them in a scratch dir the
    # way a user would, then compress THROUGH the `bzip2` name and have the
    # system's own bzip2 read the result (a second implementation agreeing),
    # and stuffr-as-`bunzip2` restore it. The output must also be
    # byte-identical to the system tool's, which is the release's promise.
    mkdir testpath/"links"
    system bin/"stuffr", "install-links", "--dir", testpath/"links"
    assert_predicate testpath/"links/bzip2", :symlink?
    (testpath/"c.txt").write "compat\n" * 1000
    cp testpath/"c.txt", testpath/"ref.txt"
    system testpath/"links/bzip2", "-k", testpath/"c.txt"
    system "/usr/bin/bzip2", "-k", testpath/"ref.txt"
    assert_equal (testpath/"ref.txt.bz2").binread, (testpath/"c.txt.bz2").binread
    assert_equal "compat\n" * 1000, shell_output("/usr/bin/bzip2 -dc #{testpath}/c.txt.bz2")
    rm testpath/"c.txt"
    system testpath/"links/bunzip2", testpath/"c.txt.bz2"
    assert_equal "compat\n" * 1000, (testpath/"c.txt").read

    # 0.12.0's headline: the gzip family. This bottle builds the pure tier, so
    # the promise is compatible output, not Apple's exact bytes: the system's
    # own gzip must read what stuffr-as-`gzip` wrote, and stuffr-as-`gunzip`
    # must restore it.
    assert_predicate testpath/"links/gzip", :symlink?
    (testpath/"g.txt").write "gzip compat\n" * 1000
    system testpath/"links/gzip", "-k", testpath/"g.txt"
    assert_equal "gzip compat\n" * 1000, shell_output("/usr/bin/gzip -dc #{testpath}/g.txt.gz")
    rm testpath/"g.txt"
    system testpath/"links/gunzip", testpath/"g.txt.gz"
    assert_equal "gzip compat\n" * 1000, (testpath/"g.txt").read

    # 0.13.0's headline: the xz family. Again compatible, not identical, on
    # this pure-tier bottle. No xz ships with macOS, but Apple's gzip decodes
    # .xz through its own liblzma, so it is the external witness here; then
    # stuffr-as-`xzcat` reads the same file back.
    assert_predicate testpath/"links/xz", :symlink?
    (testpath/"x.txt").write "xz compat\n" * 1000
    system testpath/"links/xz", "-k", testpath/"x.txt"
    assert_equal "xz compat\n" * 1000, shell_output("/usr/bin/gzip -dc #{testpath}/x.txt.xz")
    assert_equal "xz compat\n" * 1000, shell_output("#{testpath}/links/xzcat #{testpath}/x.txt.xz")

    # 0.14.0's headline: the zstd family, built on the C tier (`zstd-c`), so
    # it is libzstd 1.5.7 underneath. Compress at -19 keeping the input,
    # check the frame with -t, and read it back through `zstdcat`. The
    # version answer proves which libzstd the bottle linked.
    assert_predicate testpath/"links/zstd", :symlink?
    (testpath/"z.txt").write "zstd compat\n" * 1000
    system testpath/"links/zstd", "-q", "-19", "-k", testpath/"z.txt"
    assert_path_exists testpath/"z.txt"
    system testpath/"links/zstd", "-q", "-t", testpath/"z.txt.zst"
    assert_equal (testpath/"z.txt").read, shell_output("#{testpath}/links/zstdcat #{testpath}/z.txt.zst")
    assert_equal "1.5.7", shell_output("#{testpath}/links/zstd -qV").strip

    # 0.15.0's headline: the lz4 family, built on the C tier (`lz4-c`), so it
    # is liblz4 1.10.0 underneath. Compress at -9, test the frame, and read it
    # back through `lz4cat`; the version line names the lz4 it behaves as.
    assert_predicate testpath/"links/lz4", :symlink?
    (testpath/"l.txt").write "lz4 compat\n" * 1000
    system testpath/"links/lz4", "-q", "-9", testpath/"l.txt"
    system testpath/"links/lz4", "-q", "-t", testpath/"l.txt.lz4"
    assert_equal (testpath/"l.txt").read, shell_output("#{testpath}/links/lz4cat #{testpath}/l.txt.lz4")
    assert_match "v1.10.0", shell_output("#{testpath}/links/lz4 -V 2>&1")

    # 0.16.0's headline: the unzip family, a port of Info-ZIP UnZip 6.0 that
    # behaves as macOS's own /usr/bin/unzip here. Its listing and its test of
    # the zip stuffr packed above must be byte-identical to the system tool's,
    # and extracting through the link must restore the tree.
    assert_predicate testpath/"links/unzip", :symlink?
    assert_equal shell_output("/usr/bin/unzip -l #{testpath}/full.zip"),
                 shell_output("#{testpath}/links/unzip -l #{testpath}/full.zip")
    assert_equal shell_output("/usr/bin/unzip -t #{testpath}/full.zip"),
                 shell_output("#{testpath}/links/unzip -t #{testpath}/full.zip")
    system testpath/"links/unzip", "-q", testpath/"full.zip", "-d", testpath/"unzipped"
    assert_equal "alpha\n", (testpath/"unzipped/proj/a.txt").read
    assert_equal "beta\n", (testpath/"unzipped/proj/sub/b.bin").read

    # 0.18.0: `compress`/`uncompress` behave as Apple's /usr/bin/compress on
    # macOS — the same bytes, and the round trip restores the file.
    assert_predicate testpath/"links/compress", :symlink?
    (testpath/"lzw.txt").write "GET /index.html HTTP/1.1 200 1043\n" * 2000
    assert_equal shell_output("/usr/bin/compress -c #{testpath}/lzw.txt"),
                 shell_output("#{testpath}/links/compress -c #{testpath}/lzw.txt")
    system testpath/"links/compress", testpath/"lzw.txt"
    system testpath/"links/uncompress", testpath/"lzw.txt.Z"
    assert_equal "GET /index.html HTTP/1.1 200 1043\n" * 2000, (testpath/"lzw.txt").read
  end
end
