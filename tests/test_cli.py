from dbtbuilder import cli
from dbtbuilder.errors import DbtBuilderError

_CONFIG = (
    "version = 42\n"
    "[platforms]\n[platforms.linux]\narch = [\"x86_64\"]\n"
    "[sources]\n[packages]\n"
)


def test_toolchain_version_prints_and_exits_zero(tmp_path, capsys):
    cfg = tmp_path / "config.toml"
    cfg.write_text(_CONFIG)

    rc = cli.main(["--config", str(cfg), "--toolchain-version"])

    assert rc == 0
    assert capsys.readouterr().out.strip() == "42"


def test_dbtbuilder_error_returns_exit_code_one(monkeypatch, tmp_path):
    cfg = tmp_path / "config.toml"
    cfg.write_text(_CONFIG)

    def boom(*args, **kwargs):
        raise DbtBuilderError("boom")

    monkeypatch.setattr(cli, "run_build", boom)

    rc = cli.main(["--config", str(cfg)])

    assert rc == 1
