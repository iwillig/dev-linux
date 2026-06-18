Describe 'Editors'
  Describe 'emacs'
    It 'is installed'
      When run command emacs --version
      The status should be success
      The output should include 'GNU Emacs'
    End
  End

  Describe 'nvim'
    It 'is installed'
      When run command nvim --version
      The status should be success
      The output should include 'NVIM'
    End
  End
End

Describe 'Shell and terminal'
  Describe 'fish'
    It 'is installed'
      When run command fish --version
      The status should be success
      The output should include 'fish'
    End
  End

  Describe 'starship'
    It 'is installed'
      When run command starship --version
      The status should be success
      The output should be present
    End
  End

  Describe 'zellij'
    It 'is installed'
      When run command zellij --version
      The status should be success
      The output should be present
    End
  End

  Describe 'alacritty'
    It 'is installed'
      When run command alacritty --version
      The status should be success
      The output should be present
    End
  End

  Describe 'tmux'
    It 'is installed'
      When run command tmux -V
      The status should be success
      The output should be present
    End
  End
End

Describe 'Build tools (development-tools group)'
  Describe 'gcc'
    It 'is installed'
      When run command gcc --version
      The status should be success
      The output should be present
    End
  End

  Describe 'make'
    It 'is installed'
      When run command make --version
      The status should be success
      The output should be present
    End
  End

  Describe 'git'
    It 'is installed'
      When run command git --version
      The status should be success
      The output should be present
    End
  End
End

Describe 'CLI utilities'
  Describe 'fd'
    It 'is installed'
      When run command fd --version
      The status should be success
      The output should be present
    End
  End

  Describe 'bat'
    It 'is installed'
      When run command bat --version
      The status should be success
      The output should be present
    End
  End

  Describe 'eza'
    It 'is installed'
      When run command eza --version
      The status should be success
      The output should be present
    End
  End

  Describe 'fzf'
    It 'is installed'
      When run command fzf --version
      The status should be success
      The output should be present
    End
  End

  Describe 'jq'
    It 'is installed'
      When run command jq --version
      The status should be success
      The output should be present
    End
  End

  Describe 'yq'
    It 'is installed'
      When run command yq --version
      The status should be success
      The output should be present
    End
  End

  Describe 'zoxide'
    It 'is installed'
      When run command zoxide --version
      The status should be success
      The output should be present
    End
  End

  Describe 'ag (the silver searcher)'
    It 'is installed'
      When run command ag --version
      The status should be success
      The output should be present
    End
  End

  Describe 'pandoc'
    It 'is installed'
      When run command pandoc --version
      The status should be success
      The output should be present
    End
  End

  Describe 'stow'
    It 'is installed'
      When run command stow --version
      The status should be success
      The output should be present
    End
  End

  Describe 'rlwrap'
    It 'is installed'
      When run command rlwrap --version
      The status should be success
      The output should be present
    End
  End
End

Describe 'Node.js ecosystem'
  Describe 'node'
    It 'is installed'
      When run command node --version
      The status should be success
      The output should be present
    End
  End

  Describe 'npm'
    It 'is installed'
      When run command npm --version
      The status should be success
      The output should be present
    End
  End

  Describe 'tsc (TypeScript compiler)'
    It 'is installed'
      When run command tsc --version
      The status should be success
      The output should include 'Version'
    End
  End

  Describe 'typescript-language-server'
    It 'is installed'
      When run command typescript-language-server --version
      The status should be success
      The output should be present
    End
  End
End

Describe 'JVM ecosystem'
  Describe 'java'
    It 'is installed'
      When run command java --version
      The status should be success
      The output should be present
    End
  End

  Describe 'clojure'
    It 'is installed'
      When run command clojure --version
      The status should be success
      The output should be present
    End
  End

  Describe 'clj'
    It 'is installed'
      When run command clj --version
      The status should be success
      The output should be present
    End
  End
End
