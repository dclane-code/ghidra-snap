#!/bin/bash
unset XDG_CONFIG_HOME
# the gnome extension points PYTHONPATH at its own python stdlib, which pyghidra doesn't need
unset PYTHONPATH
exec "$@"
