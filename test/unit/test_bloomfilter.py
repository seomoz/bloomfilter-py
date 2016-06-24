#! /usr/bin/env python
'''Bloom filter test'''

import unittest
from bloomfilter import bloomfilter


class TestBloomFilter(unittest.TestCase):
    '''Bloom filter test'''

    def setUp(self):
        pass

    def tearDown(self):
        pass

    def test_foo(self):
        '''Foo function'''
        self.assertEqual(bloomfilter.foofoo(), 1)

if __name__ == '__main__':
    unittest.main()
