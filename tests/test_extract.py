import os
import stat
import tarfile

import pytest

from dbtbuilder import extract
from dbtbuilder.errors import ExtractError
from dbtbuilder.model import BuildTarget, Package, Source
from dbtbuilder.paths import BuildPaths


def test_shift_subdir_up_flattens_single_child(tmp_path):
    inner = tmp_path / "pkg" / "pkg-1.0" / "bin"
    inner.mkdir(parents=True)
    (inner / "tool").write_text("x")

    extract.shift_subdir_up("pkg", tmp_path)

    assert (tmp_path / "pkg" / "bin" / "tool").read_text() == "x"
    assert not (tmp_path / "pkg" / "pkg-1.0").exists()


def test_lift_bundle_subdir_promotes_nested_contents(tmp_path):
    # Post-shift macOS layout: pkg/CMake.app/Contents/{bin,share}/...
    contents = tmp_path / "cmake" / "CMake.app" / "Contents"
    (contents / "bin").mkdir(parents=True)
    (contents / "bin" / "cmake").write_text("bin")
    (contents / "share" / "cmake-4.3").mkdir(parents=True)
    (contents / "share" / "cmake-4.3" / "Modules").write_text("m")

    extract.lift_bundle_subdir(tmp_path / "cmake", "CMake.app/Contents")

    assert (tmp_path / "cmake" / "bin" / "cmake").read_text() == "bin"
    assert (tmp_path / "cmake" / "share" / "cmake-4.3" / "Modules").read_text() == "m"
    assert not (tmp_path / "cmake" / "CMake.app").exists()


def test_extract_raw_binary_stages_and_sets_exec_bit(tmp_path):
    paths = BuildPaths.from_root(tmp_path / "work")
    paths.cache.mkdir(parents=True)
    (paths.cache / "linux-x86_64-rustup-init").write_bytes(b"#!/bin/sh\n")

    src = Source(
        name="rust",
        url="http://example/rustup-init",
        checksum_type="sha256",
        checksum_url=None,
        ext_map={"default": ""},
    )
    pkg = Package("rustup-init", "linux", {"source": "rust", "set-executable": True}, src)
    extract.extract_target(BuildTarget(pkg, "x86_64"), paths)

    staged = paths.staging_dir("linux", "x86_64") / "rustup-init" / "rustup-init"
    assert staged.is_file()
    assert os.stat(staged).st_mode & stat.S_IXUSR


def test_untar_archive_applies_include_filter(tmp_path):
    content = tmp_path / "content" / "pkg-1.0" / "bin"
    content.mkdir(parents=True)
    (content / "keep").write_text("keep")
    (content / "drop").write_text("drop")
    tar_path = tmp_path / "archive.tar"
    with tarfile.open(tar_path, "w") as tar:
        tar.add(tmp_path / "content" / "pkg-1.0", arcname="pkg-1.0")

    include = tmp_path / "inc.txt"
    include.write_text("bin/keep\n")
    dest = tmp_path / "out"

    extract.untar_archive(tar_path, dest, include)

    files = {p.name for p in dest.rglob("*") if p.is_file()}
    assert "keep" in files
    assert "drop" not in files


def test_is_included_matches_files_and_subtrees():
    patterns = ["root/bin/cmake", "root/share"]
    # Exact file match.
    assert extract._is_included("root/bin/cmake", patterns)
    # Everything under a directory pattern is kept.
    assert extract._is_included("root/share/cmake-4.3/Modules/Foo.cmake", patterns)
    assert extract._is_included("root/share", patterns)
    # A sibling that merely shares a name prefix is not kept (boundary-aware).
    assert not extract._is_included("root/bin/cmake-gui", patterns)
    assert not extract._is_included("root/shareX/thing", patterns)


def test_load_include_patterns_skips_blank_and_comment_lines(tmp_path):
    inc = tmp_path / "f.include"
    inc.write_text("# a comment\n\nContents/bin/cmake\n   \nContents/share\n")
    assert extract._load_include_patterns(inc) == [
        "Contents/bin/cmake",
        "Contents/share",
    ]


def test_untar_archive_include_keeps_whole_subtree(tmp_path):
    base = tmp_path / "content" / "pkg-1.0" / "share" / "data"
    base.mkdir(parents=True)
    (base / "a").write_text("a")
    (base / "b").write_text("b")
    (tmp_path / "content" / "pkg-1.0" / "drop.txt").write_text("x")
    tar_path = tmp_path / "archive.tar"
    with tarfile.open(tar_path, "w") as tar:
        tar.add(tmp_path / "content" / "pkg-1.0", arcname="pkg-1.0")

    include = tmp_path / "inc.txt"
    include.write_text("share\n")  # a directory: keep the whole subtree
    dest = tmp_path / "out"

    extract.untar_archive(tar_path, dest, include)

    files = {p.name for p in dest.rglob("*") if p.is_file()}
    assert files == {"a", "b"}


def test_untar_archive_raises_on_corrupt_file(tmp_path):
    bad = tmp_path / "bad.tar"
    bad.write_text("not a tar at all")
    with pytest.raises(ExtractError):
        extract.untar_archive(bad, tmp_path / "out", tmp_path / "missing.include")
