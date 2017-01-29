'''Simple and fast implementation of Bloom filter'''

import base64
from collections import deque
import hashlib
import itertools
import random
import zlib

cimport cython.math as math
from math import ceil, exp, log
cimport cbloomfilter
from libc.stdint cimport uint64_t


__version__ = (0, 1, 0)


cdef class BloomFilter:
    '''Simple and fast implementation of Bloom filter'''
    cdef cbloomfilter.CBloomFilter* cbf

    def __cinit__(self, capacity=0, error_rate=0, _build=True):
        cdef long hash_count
        cdef long bit_count
        cdef double log2 = log(2.0)
        cdef double log_error_rate
        cdef cbloomfilter.CBloomFilter* cbf
        cdef char* seeds

        self.cbf = NULL

        if not _build:
            return

        if capacity <= 0:
            raise ValueError("BloomFilter capacity must be a positive number (%s passed)", capacity)

        if error_rate <= 0 or error_rate >= 1:
            raise ValueError("BloomFilter error rate must be in the range 0 < error rate < 1 (%s passed)", error_rate)

        log_error_rate = log(error_rate)
        hash_count = max(round(- log_error_rate / log2), 1)
        bit_count = ceil(- hash_count / log(1 - exp(log_error_rate / hash_count)) * capacity)
        # Since we are using very simplistic re-hash algorithm, we have a pathological
        # case when `bit_count` is power of 2. We alleviate it by making `bit_count` always
        # an odd number.
        bit_count |= 1
        acc = ''
        for i in xrange(hash_count):
            random_string = "".join(chr(random.randrange(256)) for j in xrange(8))
            # we are using simplistic rehasher, so we better have pretty good seeds.
            hasher = hashlib.new('md5')
            hasher.update(random_string)
            acc += hasher.digest()
        seeds = acc
        cbf = cbloomfilter.CBloomFilter_Create(hash_count, bit_count, seeds)
        if cbf == NULL:
            raise ValueError("BloomFilter cannot allocate memory for capacity=%s and error_rate=%s", capacity, error_rate)
        self.cbf = cbf

    def __dealloc__(self):
        '''Free up filter's data'''
        cbloomfilter.CBloomFilter_Destroy(self.cbf)
        self.cbf = NULL

    @property
    def byte_size(self):
        '''Size of the filter in bytes'''
        return cbloomfilter.CBloomFilter_ByteSize(self.cbf)

    @property
    def hash_count(self):
        '''Number of hashes in the filter'''
        return self.cbf.hash_count

    @property
    def bit_count(self):
        '''Number of bits in the filter'''
        return self.cbf.bit_count

    def add_by_hash(self, x):
        '''
        Add item using its Python hash to the filter

        Function returns `True` if the hash was _not_ present _before_
        the operation, `False` otherwise.
        '''
        return bool(cbloomfilter.CBloomFilter_AddHash(self.cbf, hash(x)))

    def test_by_hash(self, x):
        '''Test whether item is in the filter using its Python hash'''
        return bool(cbloomfilter.CBloomFilter_TestHash(self.cbf, hash(x)))

    def serialize(self):
        '''Serialize the filter'''
        return base64.b64encode(zlib.compress((<char*>self.cbf)[:self.byte_size], 9))

    @classmethod
    def deserialize(self, serialized_filter):
        '''Create a filter from previously serialized data'''
        data = zlib.decompress(base64.b64decode(serialized_filter))

        cbf = BloomFilter(_build=False)
        cbf.cbf = cbloomfilter.CBloomFilter_FromData(<char*> data, len(data))
        if cbf.cbf == NULL:
            raise ValueError("BloomFilter: serialized data are corrupted, or cannot allocate memory")
        return cbf


    def raw_data(self):
        '''Raw filter data, primary for debug purpose'''
        return (<char*>self.cbf)[:self.byte_size]


cdef class RotatingBloomFilter:
    '''
    Use `count` bloom filters, each configured with `capacity` and `error`. As the
    combined capacity is reached, the oldest bloom filter is removed and a new one is
    created. As such, it keeps track of roughly the most recent `count * capacity` unique
    objects:

        (count - 1) * capacity <= remembered entries <= count * capacity
    '''

    cdef uint64_t capacity
    cdef double error_rate
    cdef uint64_t count
    cdef uint64_t remaining
    cdef object blooms
    cdef object bloom

    def __init__(self, capacity, error_rate, count):
        self.capacity = capacity
        self.error_rate = error_rate
        self.count = count
        self.remaining = 0
        self.blooms = deque()
        self.bloom = None
        self.rotate()

    property blooms:
        def __get__(self):
            return self.blooms

    def rotate(self):
        '''Add a new bloom filter to our deque and remove any old bloom filters.'''
        self.bloom = BloomFilter(self.capacity, self.error_rate)
        self.blooms.append(self.bloom)
        while len(self.blooms) > self.count:
            self.blooms.popleft()
        self.remaining = self.capacity

    def add_by_hash(self, x):
        '''Add item using its Python hash to the filter.'''
        if self.test_by_hash(x):
            return False

        self.bloom.add_by_hash(x)
        self.remaining -= 1
        if self.remaining <= 0:
            self.rotate()
        return True

    def test_by_hash(self, x):
        '''Test whether item is in the filter using its Python hash.'''
        return any(bloom.test_by_hash(x) for bloom in self.blooms)

    def dedup(self, items, key=None):
        '''Generator of the unique items.'''
        predicate = self.add_by_hash
        if key is not None:
            def predicate(item):
                return self.add_by_hash(key(item))

        return itertools.ifilter(predicate, items)
