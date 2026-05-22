class Sqlt < Formula
  desc "Multi-dialect SQL parser and translator (MySQL/MariaDB/PostgreSQL/MSSQL/SQLite)"
  homepage "https://github.com/codedeviate/sqlt"
  url "https://github.com/codedeviate/sqlt/archive/refs/tags/v0.3.5.tar.gz"
  sha256 "6a1a9c5f8f176b9c9560e13544de3273ce235a7b8bb3a0a77313e152e3223173"
  license "MIT"
  head "https://github.com/codedeviate/sqlt.git", branch: "master"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: ".")
    man1.install "man/sqlt.1" if (buildpath/"man/sqlt.1").exist?
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/sqlt --version")

    parsed = pipe_output("#{bin}/sqlt parse --from mysql -", "SELECT 1;")
    assert_match "\"dialect\":\"mysql\"", parsed
    assert_match "\"statements\"", parsed

    translated = pipe_output(
      "#{bin}/sqlt translate --from mariadb --to postgres -",
      "INSERT INTO t (id) VALUES (1) RETURNING id;",
    )
    assert_match(/RETURNING/i, translated)
  end
end
