@REM This file takes all subfolders, renames xml files to xhtml and converts them to epub. requires calibre
@set /p DoRen=Willst du die Endung aller Dateien mit der Endung .xml in allen Subordnern von %cd% in .html umbenennen?[J/N]: 
@if %DoRen%== J goto RENAME
@if %DoRen%== j goto RENAME
@if not %DoRen%== J goto CONVQ
:RENAME
forfiles /S /M *.xml /C "cmd /c echo renaming file @file & rename @file @fname.xhtml"
@echo Alle Dateien wurden umbenannt!

:CONVQ
@set /p DoConv=Willst du die Umbenannten Dateien nun in ePub konvertieren?[J/N]: 
@if %DoConv%== J goto CONV
@if %DoConv%== j goto CONV
@if not %DoConv%== J goto DELTHEM

:CONV
forfiles /S /M *.xhtml /C "cmd /c echo converting @file & 0x22C:\Program Files (x86)\Calibre2\ebook-convert.exe0x22 @file @fname.epub"
@echo Alle Dateien wurden konvertiert!
@goto DELTHEM

:DELTHEM
@set /p DoDel=Willst du die .xhtml/.xml dateien nun loeschen?[J/N]: 
@if %DoDel%== J goto ACTUALDEL
@if %DoDel%== j goto ACTUALDEL
@if not %DoDel%== J goto ABORT

:ACTUALDEL
forfiles /S /M *.xhtml /C "cmd /c echo deleting @file & del @file"
@echo Alle .xhtml/.xml Dateien wurden geloescht!
forfiles /S /M *htmldir.* /C "cmd /c echo deleting @file & del @file"
forfiles /S /M *.sql /C "cmd /c echo deleting @file & del @file"
forfiles /S /M *.gif /C "cmd /c echo deleting @file & del @file"
forfiles /S /M *.jpg /C "cmd /c echo deleting @file & del @file"
forfiles /S /M *.png /C "cmd /c echo deleting @file & del @file"
forfiles /S /M *.ini /C "cmd /c echo deleting @file & del @file"
forfiles /S /M *.css /C "cmd /c echo deleting @file & del @file"
@echo Alle unnoetigen Dateien wurden geloescht!
@goto END

:ABORT
@echo Prozess wurde abgebrochen!
@pause
@exit

:END
@pause
@exit
