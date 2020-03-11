#! /usr/bin/env python

from setuptools import setup, Extension
import sys

try:
    import Cython

    pass
except ImportError:
    print("*** cannot import Cython")
    pass

if "Cython" in globals():
    print("*** info: Building from Cython")
    ext_files = ["bloomfilter/_bloomfilter.pyx"]
else:
    print("*** info: Building from C")
    ext_files = ["bloomfilter/_bloomfilter.c"]

ext_modules = [
    Extension(
        "bloomfilter._bloomfilter", ext_files, include_dirs=["bloomfilter"]
    )
]

requirements = []
if sys.version_info[0] < 3 and sys.version_info[1] < 7:
    requirements.append("importlib")

setup(
    name="bloomfilter",
    version="0.2.1",
    description="Bloom Filter (Python)",
    license="MIT License",
    url="http://github.com/seomoz/bloomfilter-py",
    author="Moz, Inc.",
    author_email="turbo@moz.com",
    packages=["bloomfilter"],
    package_dir={"bloomfilter": "bloomfilter"},
    install_requires=[requirements],
    tests_require=["coverage", "nose", "pylint"],
    scripts=[],
    ext_modules=ext_modules,
    test_suite="test",
    classifiers=[
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: C",
        "Programming Language :: Cython",
        "Programming Language :: Python",
        "Operating System :: OS Independent",
        "Topic :: Software Development :: Libraries :: Python Modules",
    ],
)
