class Sqlt < Formula
  desc "Multi-dialect SQL parser and translator (MySQL/MariaDB/PostgreSQL/MSSQL/SQLite)"
  homepage "https://github.com/codedeviate/sqlt"
  url "https://github.com/codedeviate/sqlt/archive/refs/tags/v0.3.3.tar.gz"
  sha256 "4e01e1b1df893007c8baa63794a8e0888ef37d0fc076a3d9c018b382b5a0d159"
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
