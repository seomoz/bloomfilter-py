.PHONY: test
test: lint
	nosetests --with-coverage --rednose test/unit

.PHONY: lint
lint:
	pylint bloomfilter/ test/
	pep8   bloomfilter/ test/

install:
	python setup.py install

clean:
	rm -rf build dist *.egg-info
	find . -name '*.pyc' | xargs --no-run-if-empty rm
