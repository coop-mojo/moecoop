@echo off
dub build -a x86_64 -b release
7za a -tzip moecoop.zip fukuro.exe LICENSE README.md resource doc libfreetype-6.dll
