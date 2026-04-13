ECHO ***********************************
ECHO Preparing account data for new year
ECHO ***********************************
d:
md %2ap.102
md %2ar.102
md %2ml.102
copy %1ap.102\*.* %2ap.102
cd %2ap.102
\emptyacc
cd ..
copy %1ar.102\*.* %2ar.102
cd %2ar.102
\emptyacc
cd ..
copy %1ml.102\*.* %2ml.102
