#!/bin/bash

packer build --only=$1-iso windows_11.json

