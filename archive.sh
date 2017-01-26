#!/bin/sh

dub build -c server -b release
strip fukurod
tar cvzf moecoop.tgz fukurod LICENSE README.md resource docs
rm fukurod
