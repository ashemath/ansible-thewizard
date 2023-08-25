#!/bin/sh

python3 -m venv .
. bin/activate
pip install --upgrade pip
pip install ansible
