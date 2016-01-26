@echo off
dub build
7za a -tzip moecoop.zip fukuro.exe LICENSE README.md resource doc libfreetype-6.dll
