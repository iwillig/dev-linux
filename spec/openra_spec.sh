# shellcheck shell=bash
Describe 'OpenRA development dependencies'
  It 'has the .NET 10 SDK'
    When run command dotnet --list-sdks
    The status should be success
    The output should include '10.0.'
  End

  It 'has the Fedora system libraries including Lua 5.1'
    When run command rpm -q sdl2-compat freetype compat-lua-libs openal-soft
    The status should be success
    The output should include 'compat-lua-libs-5.1.'
  End
End
