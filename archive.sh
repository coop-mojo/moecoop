#!/bin/sh

dub upgrade
sed -i -e 's/^.\+openssl.\+$//' dub.selections.json
dub build -c server -b release
strip fukurod
tar cvzf moecoop.tgz fukurod LICENSE README.md resource docs
rm fukurod
