Describe 'Fonts'
  Describe 'JetBrains Mono'
    It 'is registered with fontconfig'
      When run sh -c 'fc-list | grep -q "JetBrains Mono"'
      The status should be success
    End
  End

  Describe 'JetBrains Mono Nerd Font (patched)'
    It 'is registered with fontconfig'
      When run sh -c 'fc-list | grep -q "JetBrainsMono Nerd Font"'
      The status should be success
    End
  End

  Describe 'Cascadia Code'
    It 'is registered with fontconfig'
      When run sh -c 'fc-list | grep -q "Cascadia Code"'
      The status should be success
    End
  End

  Describe 'Inter'
    It 'is registered with fontconfig'
      When run sh -c 'fc-list | grep -q "Inter"'
      The status should be success
    End
  End

  Describe 'Noto Emoji'
    It 'is registered with fontconfig'
      When run sh -c 'fc-list | grep -qi "Noto.*Emoji"'
      The status should be success
    End
  End
End
