#! /usr/bin/env python
"""Bloom filter collision tests"""

# pylint: disable=invalid-name

import os
import unittest
from bloomfilter import BloomFilter


class TestCollisions(unittest.TestCase):
    """Set of tests to ensure desirable collision rate"""

    def test_non_randoms_at_all(self):
        """Ensure that small bit differences do not play bad"""
        bloom_filter = BloomFilter(1000000, 1e-5)
        collision_count = 0
        for ix in range(1000000):
            if bloom_filter.test_by_hash(ix):
                collision_count += 1
            else:
                bloom_filter.add_by_hash(ix)
        self.assertEqual(collision_count, 0)

    def test_objects(self):
        """Ensure that objects work well"""
        # hash of object (with no __hash__) is its address, so it is
        # not overly random
        #
        # Nota Bene!: since memory is reused, there is a real
        # possibility of object hash collisions.
        #
        # For example:
        #     for ix in xrange(1000000):
        #       obj = object()
        # produces objects with exactly two hashes.
        bloom_filter = BloomFilter(1000000, 1e-5)
        collision_count = 0
        objects = [object() for _ in range(1000000)]
        for obj in objects:
            if bloom_filter.test_by_hash(obj):
                collision_count += 1
            else:
                bloom_filter.add_by_hash(obj)
        self.assertEqual(collision_count, 0)

    def test_words(self):
        """Ensure that strings work well"""
        vocabulary = self.load_words("words")
        test_words = self.load_words("testwords")
        bloom_filter = BloomFilter(100000, 1e-4)

        intersection = set(vocabulary) & set(test_words)

        setup_collision_count = 0
        for word in vocabulary:
            if bloom_filter.test_by_hash(word):
                setup_collision_count += 1
            else:
                bloom_filter.add_by_hash(word)
        self.assertLess(setup_collision_count, 5)

        false_positive_count = 0
        false_negative_count = 0
        for word in test_words:
            if word in intersection:
                if not bloom_filter.test_by_hash(word):
                    false_negative_count += 1
            else:
                if bloom_filter.test_by_hash(word):
                    false_positive_count += 1
        self.assertEqual(false_negative_count, 0)
        self.assertLessEqual(false_positive_count, 6)

    def load_words(self, file_name):
        """Load word list from the local file"""
        test_dir = os.path.dirname(__file__)
        with open(os.path.join(test_dir, file_name), "r") as infile:
            return [word for word in infile.read().split("\n") if word]
