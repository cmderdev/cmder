#!/bin/bash

packer build --force --only=$1-iso windows_10.json
