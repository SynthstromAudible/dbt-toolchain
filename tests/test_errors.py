import pytest

from dbtbuilder import __version__
from dbtbuilder.errors import (
    ChecksumMismatch,
    ConfigError,
    DbtBuilderError,
    DownloadError,
    ExtractError,
)


def test_version_is_a_string():
    assert isinstance(__version__, str)


@pytest.mark.parametrize("exc", [ConfigError, DownloadError, ChecksumMismatch, ExtractError])
def test_all_errors_subclass_base(exc):
    assert issubclass(exc, DbtBuilderError)
    with pytest.raises(DbtBuilderError):
        raise exc("boom")
