@echo off
dub build -a %1 -b %2 --compiler=%3

powershell -Command Compress-Archive -Path fukuro.exe, LICENSE, README.md, resource, docs -DestinationPath moecoop-%1.zip

if %1==x86_64 (
    powershell -Command Compress-Archive -Path migemo.dll -DestinationPath moecoop-%1.zip -Update
    del migemo.dll
    rd resource\dict\dict
)
del fukuro.exe
