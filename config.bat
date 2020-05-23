@echo off

del src\Stickman.dof
del src\Stickman.cfg
echo Creating project settings
(
  echo [FileVersion]
  echo Version=7.0
  echo [Compiler]
  echo UnsafeType=0
  echo UnsafeCode=0
  echo UnsafeCast=0
  echo [Directories]
  echo OutputDir=..\runtime
  echo UnitOutputDir=units
  echo SearchPath=..\libs;..\libs\Indy\Lib\Core;..\libs\Indy\Lib\System;..\libs\Indy\Lib\Protocols;..\libs\dx9
  if defined CRYPTO (
    echo Conditionals=CRYPTO
  )
)> src\Stickman.dof

echo Done