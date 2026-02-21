echo off
echo Beginning installation...
echo =========================
echo on

mkdir c:\ssm
subst d: c:\ssm

copy a:menu.com d:
copy a:*.chn d:
copy a:backup.bat d:
copy a:restore.bat d:
copy a:newyear.bat d:
copy a:pk*.exe d:

echo off
echo Done with installation.
echo =========================
echo Starting menu...
echo on
d:
menu
