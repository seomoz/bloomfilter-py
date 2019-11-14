.PHONY: lint
lint:
	pylint bloomfilter/ test/
	pycodestyle   bloomfilter/ test/

.PHONY: build
build:
	python setup.py build_ext --inplace

.PHONY: test
test: build
	nosetests --with-coverage --with-timer --rednose test

.PHONY: install
install:
	python setup.py install

.PHONY: build-egg
build-egg:
	python setup.py bdist_egg

.PHONY: clean
clean:
	rm -rf build dist *.egg-info bloomfilter/_bloomfilter.c
	find . -name '*.pyc' | xargs --no-run-if-empty rm
	find . -name '*.so' | xargs --no-run-if-empty rm
