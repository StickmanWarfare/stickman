@ECHO off
del /s stickman.zip
7z a -tzip "stickman.zip" .\runtime\* -r -xr!cfg -xr!screenshots -x!log.* -x!*.docx
