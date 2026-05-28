@echo off
"MinGit\cmd\git.exe" clone "https://github.com/Lunas-Lab/Archivists-Assistant.git"

cd %~dp0

echo Would you like to install shortcuts to the Start Menu and Desktop? You can always run ""CreateShortcuts.bat"" later to make them too.
CHOICE /C YN /M "Press Y for Yes or N for No: "
if ERRORLEVEL 2 GOTO END

"%~dp0\Archivists-Assistant\CreateShortcuts.bat"

:END
echo Archivists Assistant has been installed.
pause
del "%~dp0\Install.bat"