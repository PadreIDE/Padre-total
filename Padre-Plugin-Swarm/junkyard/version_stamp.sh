#!/bin/bash
find lib -type f -exec \
sed -i -e "s|VERSION = .*|VERSION = '$NEWVERSION';|g"  '{}' \;
