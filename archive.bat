@echo off
dub build -a %1 -b %2
powershell -Command Compress-Archive -Path fukuro.exe, LICENSE, README.md, resource, docs, libcurl.dll -DestinationPath moecoop-%1.zip
del fukuro.exe libcurl.dll
