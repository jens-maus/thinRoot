#!/bin/sh

tar -C overlay -cvJf overlay.pkg --owner=root --group=root .
chmod a+r overlay.pkg
