CC      = gcc
CCOPTS  = -shared -pthread -fPIC -fwrapv -O3 -Wall -fno-strict-aliasing
PYINC = $(shell python -c "from distutils import sysconfig; print sysconfig.get_python_inc()")
PYLIB = $(shell python -c "from distutils import sysconfig; print sysconfig.get_config_var('LIBS')")

SRC = bloomfilter/_bloomfilter.pyx bloomfilter/cbloomfilter.pxd bloomfilter/cbloomfilter.h

.PHONY: lint
lint:
	pylint bloomfilter/ test/
	pep8   bloomfilter/ test/

bloomfilter/_bloomfilter.c: $(SRC)
	cython bloomfilter/_bloomfilter.pyx

bloomfilter/_bloomfilter.so: bloomfilter/_bloomfilter.c
	$(CC) $(CCOPTS) -o $@ $< -I ./bloomfilter -I $(PYINC) -L $(PYLIB)

.PHONY: test
test: bloomfilter/_bloomfilter.so
	nosetests --with-coverage --rednose test/unit

.PHONY: install
install:
	python setup.py install

.PHONY: build-egg
build-egg:
	python setup.py bdist_egg

.PHONY: clean
clean:
	rm -rf build dist *.egg-info
	find . -name '*.pyc' | xargs --no-run-if-empty rm
	find . -name '*.so' | xargs --no-run-if-empty rm
