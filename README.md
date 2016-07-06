bloomfilter-py
==============
![Status: Incubating](https://img.shields.io/badge/status-incubating-blue.svg?style=flat)
![Team: Big Data](https://img.shields.io/badge/team-big_data-green.svg?style=flat)
![Scope: Internal](https://img.shields.io/badge/scope-internal-green.svg?style=flat)
![Open Source: No](https://img.shields.io/badge/open_source-no-red.svg?style=flat)
![Critical: Yes](https://img.shields.io/badge/critical-yes-red.svg?style=flat)
![Replaces: pybloomfiltermmap](https://img.shields.io/badge/replaces-pybloomfiltermmap-blue.svg?style=flat)

A simple and fast version of Bloom filter.

Goals
=====
1. Produce viable functionality.

    Current solution (`pyblooomfiltermmap`) is overly complicated, supports a lot
    of unused functionality, and virtually not maintained. Fixing the bugs might
    be obstructed by the data compatibility requirements (e.g., those that we do
    not have at all).
    
    We can considerably simplify things by implementing core functionality and
    taking responsibility for maintenance.

1. Align with development process.

    * Ensure coding standard compliance (on all levels).
    
    * Use standard `Vagrant` / `make` based workflow.


Usage
=====

```py
from bloomfilter import BloomFilter

# basic use
bf = BloomFilter(capacity=100, error_rate=1e-4)

bf.add_by_hash('abc')
bf.add_by_hash(u'def')

assert bf.test_by_hash('abc')
assert bf.test_by_hash(u'def')

# Because in Python `'abc' == u'abc'`, 
# this means the following are also true:
assert bf.test_by_hash(u'abc')
assert bf.test_by_hash('def')

# serialization and deserialization
serialized = bf.serialize()

new_bf = BloomFilter.deserialize(serialized)

assert new_bf.test_by_hash('abc')
assert new_bf.test_by_hash(u'def')
assert new_bf.test_by_hash(u'abc')
assert new_bf.test_by_hash('def')
```


Development
===========

Environment
-----------
Development is done in `vagrant`. To launch the `vagrant` image, we only need to
`vagrant up` (though you may have to provide a `--provider` flag):

```bash
vagrant up
```

With a running `vagrant` instance, you can log in and run tests:

```bash
vagrant ssh
cd /vagrant

make test
```

Running Tests
-------------
Tests are run with the top-level `Makefile`:

```bash
make test
```

It is also possible to run then as 

```bash
python setup.py test
```

Contribution
============
Refer to the
[guidelines for Big Data](https://github.com/seomoz/docs/blob/master/bigdata/contributing.md)
for details about how to contribute to this project.

Tagging and Versioning
======================
Whenever the version included in `setup.py` is changed (and it should be changed when
appropriate using [http://semver.org/](http://semver.org/)), a corresponding tag should
be created with the same version number (formatted `v<version>`).

```bash
git tag -a v0.1.0 -m 'Version 0.1.0

This release contains an initial working version of the `crawl` and `parse`
utilities.'

git push origin
```
