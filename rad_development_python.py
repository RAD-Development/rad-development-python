"""common."""

import itertools
import logging
import sys


def configure_logger(level: str = "INFO") -> None:
    """Configure the logger.

    Args:
        level (str, optional): The logging level. Defaults to "INFO".
    """
    logging.basicConfig(
        level=level,
        datefmt="%Y-%m-%dT%H:%M:%S%z",
        format="%(asctime)s %(levelname)s %(filename)s:%(lineno)d - %(message)s",
        handlers=[logging.StreamHandler(sys.stdout)],
    )

def partition(predicate, iterable):
    """Partition entries into false entries and true entries.

    If *predicate* is slow, consider wrapping it with functools.lru_cache().
    """
    # partition(is_odd, range(10)) → 0 2 4 6 8   and  1 3 5 7 9
    t1, t2 = itertools.tee(iterable)
    return itertools.filterfalse(predicate, t1), filter(predicate, t2)

def bash_wrapper(command: str, path: str = ".") -> tuple[str, str, int]:
    """Execute a bash command and capture the output.

    Args:
        command (str): The bash command to be executed.
        path (str): The current working directory, '.' by default

    Returns:
        Tuple[str, int]: A tuple containing the output of the command (stdout) as a string,
        the error output (stderr) as a string (optional), and the return code as an integer.
    """
    # This is a acceptable risk
    process = Popen(command.split(), stdout=PIPE, stderr=PIPE, cwd=path)  # noqa: S603
    output, error = process.communicate()

    return output.decode(), error.decode(), process.returncode
