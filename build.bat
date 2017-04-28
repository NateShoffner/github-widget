@echo off

echo Compiling script...
echo.

call coffee -c github-widget.coffee

echo Minifying script...
echo.

compiler.jar --compilation_level SIMPLE_OPTIMIZATIONS --js github-widget.js --js_output_file github-widget.min.js

echo Done!
echo.

pause