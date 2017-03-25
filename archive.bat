@echo off

dub upgrade
dub build -c mui -a %1 -b %2

powershell -Command Compress-Archive -Path fukuro.exe, LICENSE, README.md, docs, libeay32.dll, ssleay32.dll -DestinationPath moecoop-%1.zip

if %1==x86 (
    powershell -Command Compress-Archive -Path libevent.dll -DestinationPath moecoop-%1.zip -Update
)

del fukuro.exe
