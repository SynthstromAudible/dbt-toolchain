import hashlib
import tarfile

from dbtbuilder import package
from dbtbuilder.paths import BuildPaths


def test_package_dist_builds_tar_with_prefixed_members_and_hashes(tmp_path):
    paths = BuildPaths.from_root(tmp_path)
    staging = paths.staging_dir("linux", "x86_64")
    (staging / "bin").mkdir(parents=True)
    (staging / "bin" / "tool").write_text("hi")
    paths.dist.mkdir(parents=True)

    package.package_dist(25, "linux", "x86_64", paths)

    archive = paths.dist / "dbt-toolchain-25-linux-x86_64.tar.gz"
    assert archive.is_file()

    md5_file = paths.dist / "dbt-toolchain-25-linux-x86_64.tar.gz.md5"
    sha_file = paths.dist / "dbt-toolchain-25-linux-x86_64.tar.gz.sha256"
    assert md5_file.read_text() == hashlib.md5(archive.read_bytes()).hexdigest()
    assert sha_file.read_text() == hashlib.sha256(archive.read_bytes()).hexdigest()

    with tarfile.open(archive) as t:
        names = set(t.getnames())
    assert "linux-x86_64/VERSION" in names
    assert "linux-x86_64/bin/tool" in names


def test_package_dist_noop_when_staging_missing(tmp_path):
    paths = BuildPaths.from_root(tmp_path)
    paths.dist.mkdir(parents=True)
    package.package_dist(25, "linux", "arm64", paths)  # no staging dir
    assert list(paths.dist.iterdir()) == []
