@echo off

cd ..
del "%appdata%\Microsoft\Windows\Start Menu\Programs\Archivists Assistant.lnk"
del "%userprofile%\Desktop\Archivists Assistant.lnk"
rmdir /s /q "%~dp0"

echo "So long, archivist..."
pause