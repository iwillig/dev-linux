Describe 'Java'
  It 'is OpenJDK 25'
    When run command java --version
    The status should be success
    The output should include 'openjdk 25'
  End
End

Describe 'Node.js'
  It 'is v22.x'
    When run command node --version
    The status should be success
    The output should match pattern 'v22*'
  End
End

Describe 'Emacs'
  It 'is version 30.x'
    When run command emacs --version
    The status should be success
    The output should include 'GNU Emacs 30'
  End
End
