#! /usr/bin/env python
"""Bloom filter util test."""

# pylint: disable=invalid-name

import random
import unittest

import bloomfilter
import bloomfilter.util


class TestUtilDerandomize(unittest.TestCase):
    """Bloom filter derandomization tests."""

    def test_derandomize_ensures_comparable_filters(self):
        """Derandomize ensures that filters are comparable."""
        with bloomfilter.util.derandomize():
            bloom_filter_1 = bloomfilter.BloomFilter(10, 0.1)
        with bloomfilter.util.derandomize():
            bloom_filter_2 = bloomfilter.BloomFilter(10, 0.1)

        self.assertEqual(bloom_filter_1.raw_data(),
                         bloom_filter_2.raw_data())

    def test_derandomize_ensures_serialization_is_consistent(self):
        """Derandomize ensures that serialization_is_consistent."""
        with bloomfilter.util.derandomize(234):
            bloom_filter_1 = bloomfilter.BloomFilter(10, 0.1)
        with bloomfilter.util.derandomize(234):
            bloom_filter_2 = bloomfilter.BloomFilter(10, 0.1)

        self.assertEqual(bloom_filter_1.serialize(),
                         bloom_filter_2.serialize())

    def test_derandomize_allows_exceptions(self):
        """Derandomize propagates exception, but restores random state."""
        state = random.getstate()
        with self.assertRaises(ValueError):
            with bloomfilter.util.derandomize(234):
                raise ValueError("boom!")
        self.assertEqual(random.getstate(), state)
