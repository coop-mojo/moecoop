@echo off
dub build -a x86_64 -b release
7z a -tzip moecoop.zip fukuro.exe LICENSE README.md resource doc libcurl.dll
