#! /usr/bin/env python

from setuptools import setup

setup(name           = 'bloomfilter',
    version          = '0.1.0',
    description      = 'Bloom Filter (Python)',
    url              = 'http://github.com/seomoz/bloomfilter-py',
    author           = 'Big Data',
    author_email     = 'vadim@moz.com',
    packages         = [
        'bloomfilter',
    ],
    package_dir      = {
        'bloomfilter': 'bloomfilter',
    },
    install_requires = [
    ],
    tests_require    = [
        'coverage',
        'nose',
        'pylint',
    ],
    scripts = [
    ],
    classifiers      = [
        'Programming Language :: Python',
        'Intended Audience :: Developers',
        'Operating System :: OS Independent',
        'Topic :: Internet :: WWW/HTTP'
    ],
)
