@echo off

SET ROMNAME=mspaint

echo - Compiling -
rgbasm -o ../build/%ROMNAME%.o Main.asm

cd ../build/

echo(
echo - Linking -
rgblink -m %ROMNAME%.map -n %ROMNAME%.sym -o %ROMNAME%.gb -p 0xFF %ROMNAME%.o

echo(
echo - Patching -
REM Look into what -p0 specifically does
rgbfix -v -p0 %ROMNAME%.gb