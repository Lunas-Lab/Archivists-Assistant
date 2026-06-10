@echo off

echo "Creating Desktop and Start Menu shortcuts for Archivists Assistant"

cd %~dp0
powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%appdata%\Microsoft\Windows\Start Menu\Programs\Archivists Assistant.lnk');$s.TargetPath='%cd%\Archivists Assistant.bat'; $s.IconLocation='%cd%\The Archivists Assistant.ico'; $s.Save()"
powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%userprofile%\Desktop\Archivists Assistant.lnk');$s.TargetPath='%cd%\Archivists Assistant.bat'; $s.IconLocation='%cd%\The Archivists Assistant.ico'; $s.Save()"

echo "Shortcuts created!"
pause