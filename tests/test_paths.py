from pathlib import Path

from dbtbuilder.paths import BuildPaths


def test_paths_derive_from_root(tmp_path):
    p = BuildPaths.from_root(tmp_path)
    assert p.dist == tmp_path / "dist"
    assert p.staging == tmp_path / "staging"
    assert p.cache == tmp_path / "cache"
    assert p.staging_dir("linux", "x86_64") == tmp_path / "staging" / "linux-x86_64"


def test_from_root_defaults_to_cwd():
    p = BuildPaths.from_root()
    assert p.root == Path.cwd().resolve()
