bloomfilter-py
==============
[![Build Status](https://travis-ci.org/seomoz/bloomfilter-py.svg?branch=master)](https://travis-ci.org/seomoz/bloomfilter-py)

![Status: Incubating](https://img.shields.io/badge/status-incubating-blue.svg?style=flat)
![Team: Big Data](https://img.shields.io/badge/team-big_data-green.svg?style=flat)
![Scope: External](https://img.shields.io/badge/scope-external-green.svg?style=flat)
![Open Source: Yes](https://img.shields.io/badge/open_source-MIT-green.svg?style=flat)
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

### Simple Bloom filter:

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

### Rotating Bloom filter:

Rotating bloom filter exposes the same interface as a simple one. It is
better suited for data streaming applications, when number of tests is
practically unlimited. To handle the situation, up to `count` simple
filters are created. Only the last created filter is updated, but all
the filters are checked. Once the last filter reaches its capacity, the
oldest one is removed, and a new one is created. So, unlike simple bloom
filter, the rotating bloom filter check against last `count * capacity`
samples, not against all in its history.

For now, rotating bloom filters cannot be serialized/deserialized.

```py
from bloomfilter import RotatingBloomFilter

# basic use
bf = RotatingBloomFilter(capacity=100, error_rate=1e-4, count=3)

bf.add_by_hash('abc')
bf.add_by_hash(u'def')

assert bf.test_by_hash('abc')
assert bf.test_by_hash(u'def')

# Because in Python `'abc' == u'abc'`,
# this means the following are also true:
assert bf.test_by_hash(u'abc')
assert bf.test_by_hash('def')
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

Teleport to `vagrant` VM:

```bash
vagrant ssh
```

With a running `vagrant` instance, you can log in and run tests:

```bash
cd /vagrant

source venv/bin/activate

make test
```

Running Tests & checks
-------------
Tests are run with the top-level `Makefile`:

```bash
make test
```

Code style checks:

```bash
make lint
```

It is also possible to run tests as

```bash
python setup.py test
```

PRs
===
These are not all hard-and-fast rules, but in general PRs have the
following expectations:

- __pass Travis__ -- or more generally, whatever CI is used for the particular project
- __be a complete unit__ -- whether a bug fix or feature, it should appear as a complete
    unit before consideration.
- __maintain code coverage__ -- some projects may include code coverage requirements as
    part of the build as well
- __maintain the established style__ -- this means the existing style of established
    projects, the established conventions of the team for a given language on new
    projects, and the guidelines of the community of the relevant languages and
    frameworks.
- __include failing tests__ -- in the case of bugs, failing tests demonstrating the bug
    should be included as one commit, followed by a commit making the test succeed. This
    allows us to jump to a world with a bug included, and prove that our test in fact
    exercises the bug.
- __be reviewed by one or more developers__ -- not all feedback has to be accepted, but
    it should all be considered.
- __avoid 'addressed PR feedback' commits__ -- in general, PR feedback should be rebased
    back into the appropriate commits that introduced the change. In cases, where this
    is burdensome, PR feedback commits may be used but should still describe the changed
    contained therein.

PR reviews consider the design, organization, and functionality of the submitted code.

Commits
=======
Certain types of changes should be made in their own commits to
improve readability. When too many different types of changes happen
simultaneous to a single commit, the purpose of each change is
muddled. By giving each commit a single logical purpose, it is
implicitly clear why changes in that commit took place.

- __updating / upgrading dependencies__ -- this is especially true for invocations like
    `bundle update` or `berks update`.
- __introducing a new dependency__ -- often preceeded by a commit updating existing
    dependencies, this should only include the changes for the new dependency.
- __refactoring__ -- these commits should preserve all the existing functionality and
    merely update how it's done.
- __utility components to be used by a new feature__ -- if introducing an auxiliary class
    in support of a subsequent commit, add this new class (and its tests) in its own
    commit.
- __config changes__ -- when adjusting configuration in isolation
- __formatting / whitespace commits__ -- when adjusting code only for stylistic purposes.

New Features
------------
Small new features (where small refers to the size and complexity of
the change, not the impact) are often introduced in a single
commit. Larger features or components might be built up piecewise,
with each commit containing a single part of it (and its corresponding
tests).

Bug Fixes
---------
In general, bug fixes should come in two-commit pairs: a commit adding
a failing test demonstrating the bug, and a commit making that failing
test pass.

Tagging and Versioning
======================
Whenever the version included in `setup.py` is changed (and it should
be changed when appropriate using
[http://semver.org/](http://semver.org/)), a corresponding tag should
be created with the same version number (formatted `v<version>`).

```bash
git tag -a v0.1.0 -m 'Version 0.1.0

This release contains an initial working version of the `crawl` and `parse`
utilities.'

git push origin
```
