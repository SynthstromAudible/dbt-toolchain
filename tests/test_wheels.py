from dbtbuilder import wheels
from dbtbuilder.paths import BuildPaths


def test_add_python_lib_copies_wheels_to_other_platforms(monkeypatch, tmp_path):
    paths = BuildPaths.from_root(tmp_path)
    monkeypatch.setattr(wheels, "get_sysname_arch", lambda: ("linux", "x86_64"))

    fake_wheel = tmp_path / "foo-1.0-py3-none-any.whl"
    fake_wheel.write_text("wheel-bytes")

    def fake_check_output(cmd, stderr=None):
        return f"Saved {fake_wheel}\n".encode()

    monkeypatch.setattr(wheels.subprocess, "check_output", fake_check_output)

    wheels.add_python_lib("foo", [("linux", "x86_64"), ("darwin", "arm64")], paths)

    copied = paths.staging_dir("darwin", "arm64") / "python" / "wheel" / fake_wheel.name
    assert copied.is_file()
    assert copied.read_text() == "wheel-bytes"


def test_add_python_lib_raises_when_pip_fails(monkeypatch, tmp_path):
    import subprocess

    from dbtbuilder.errors import DbtBuilderError

    paths = BuildPaths.from_root(tmp_path)
    monkeypatch.setattr(wheels, "get_sysname_arch", lambda: ("linux", "x86_64"))

    def boom(cmd, stderr=None):
        raise subprocess.CalledProcessError(1, cmd, output=b"pip exploded")

    monkeypatch.setattr(wheels.subprocess, "check_output", boom)

    try:
        wheels.add_python_lib("foo", [("linux", "x86_64")], paths)
    except DbtBuilderError:
        return
    raise AssertionError("expected DbtBuilderError")
