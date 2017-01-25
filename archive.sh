#!/bin/sh

dub build -c server -b release
strip fukurod
zip -r moecoop.zip fukurod LICENSE README.md resource docs
rm fukurod
