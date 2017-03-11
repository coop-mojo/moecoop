@echo off

dub upgrade
dub build -c mui -a %1 -b %2

powershell -Command Compress-Archive -Path fukuro.exe, LICENSE, README.md, resource, docs, libeay32.dll, ssleay32.dll -DestinationPath moecoop-%1.zip

if %1==x86_64 (
    powershell -Command Compress-Archive -Path migemo.dll -DestinationPath moecoop-%1.zip -Update
    del migemo.dll
    rd resource\dict\dict
)
del fukuro.exe
