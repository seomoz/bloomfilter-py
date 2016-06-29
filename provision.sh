#! /usr/bin/env bash

# Some dependencies
apt-get install -y make g++ gdb git python-dev python-pip

pip install -r /vagrant/requirements.txt
