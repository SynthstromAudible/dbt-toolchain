"""Exception hierarchy for dbtbuilder.

Library code raises these; only cli.main() catches them and turns them into a
process exit code. Nothing prints-and-continues.
"""


class DbtBuilderError(Exception):
    """Base class for every dbtbuilder failure."""


class ConfigError(DbtBuilderError):
    """config.toml is missing keys, malformed, or references unknown names."""


class DownloadError(DbtBuilderError):
    """An HTTP fetch or file download failed."""


class ChecksumMismatch(DbtBuilderError):
    """A downloaded file's digest did not match its published checksum."""


class ExtractError(DbtBuilderError):
    """An archive could not be extracted."""
