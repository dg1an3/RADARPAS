echo off
echo Please insert backup disk in drive A:
pause
pkzip -&wprex a:accsysbk.zip d:\*.*
copy d:\pkunzip.exe A:
copy d:\restore.bat A:
