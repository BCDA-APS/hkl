-- Compilation de la librairie � l'aide des fichiers MakeFile
- win32 nmake :
dans la console dos,
executer '%SOLEIL_ROOT%\env\soleil-env.bat'
executer nmake /f Makefile.vc
(le fichier Makefile.vc d�pend de '%SOLEIL_ROOT%\env\common_target.opt' et '%SOLEIL_ROOT%\env\tango.opt')
