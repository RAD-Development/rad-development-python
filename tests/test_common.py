"""test_common."""

from rad_development_python import configure_logger


def test_configure_logger() -> None:
    """test_configure_logger."""
    configure_logger("DEBUG")
