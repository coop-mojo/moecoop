@echo off
dub build -a %1 -b release
powershell -Command Compress-Archive -Path fukuro.exe, LICENSE, README.md, resource, docs, libcurl.dll -DestinationPath moecoop-%1.zip
