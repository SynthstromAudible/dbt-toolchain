from dbtbuilder import orchestrate
from dbtbuilder.model import Config, Package, Source
from dbtbuilder.paths import BuildPaths


def _tiny_config():
    src = Source("s", "http://x/{name}", "sha256", None, ext_map={"default": ""})
    packages = [
        Package("a", "linux", {"source": "s"}, src),
        Package("a", "darwin", {"source": "s"}, src),
    ]
    return Config(
        version=25,
        platforms={"linux": ["x86_64"], "darwin": ["arm64"]},
        sources={"s": src},
        packages=packages,
    )


def test_only_download_runs_download_and_nothing_else(monkeypatch, tmp_path):
    calls = []
    monkeypatch.setattr(orchestrate.download, "download_target", lambda t, p: calls.append("dl"))
    monkeypatch.setattr(orchestrate.extract, "extract_target", lambda *a, **k: calls.append("ex"))
    monkeypatch.setattr(orchestrate.wheels, "add_python_lib", lambda *a, **k: calls.append("wh"))
    monkeypatch.setattr(orchestrate.package, "package_dist", lambda *a, **k: calls.append("pk"))

    orchestrate.run_build(_tiny_config(), BuildPaths.from_root(tmp_path), only="download")

    assert calls == ["dl", "dl"]  # two targets, download only


def test_platform_filter_restricts_targets(monkeypatch, tmp_path):
    seen = []
    monkeypatch.setattr(
        orchestrate.download, "download_target", lambda t, p: seen.append(t.platform)
    )
    monkeypatch.setattr(orchestrate.extract, "extract_target", lambda *a, **k: None)
    monkeypatch.setattr(orchestrate.wheels, "add_python_lib", lambda *a, **k: None)
    monkeypatch.setattr(orchestrate.package, "package_dist", lambda *a, **k: None)

    orchestrate.run_build(
        _tiny_config(),
        BuildPaths.from_root(tmp_path),
        platforms=["linux"],
        only="download",
    )

    assert set(seen) == {"linux"}
