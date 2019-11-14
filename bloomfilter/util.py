"""Bloomfilter helpers."""

import contextlib
import random


@contextlib.contextmanager
def derandomize(seed=123):
    """
    Disable randomization for a block.

    Since bloomfilter generates hash seeds randomly, it is inherently an
    unstable object. It considerably complicates testing.

    This helper addresses the issue:

        with bloomfilter.util.derandomize():
            bloom_filter_1 = BloomFilter(100, 0.1)

        with bloomfilter.util.derandomize():
            bloom_filter_2 = BloomFilter(100, 0.1)

    The resulting bloom_filters are stable between runs.
    """
    state = random.getstate()
    try:
        random.seed(seed)
        yield
    finally:
        random.setstate(state)
