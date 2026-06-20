Describe 'llama.cpp — local LLM inference'
  Describe 'install layout'
    It 'has the install directory'
      When run command sh -c 'test -d /usr/lib/llama.cpp'
      The status should be success
    End

    It 'bundles libggml in the install directory'
      When run command sh -c 'ls /usr/lib/llama.cpp/libggml.so.0'
      The status should be success
      The output should include 'libggml'
    End
  End

  Describe 'llama-cli'
    It 'is on PATH via symlink'
      When run command sh -c 'test -L /usr/bin/llama-cli'
      The status should be success
    End

    It 'reports its version'
      When run command sh -c 'llama-cli --version 2>&1'
      The status should be success
      The output should be present
    End
  End

  Describe 'llama-server'
    It 'is on PATH via symlink'
      When run command sh -c 'test -L /usr/bin/llama-server'
      The status should be success
    End

    It 'reports its version'
      When run command sh -c 'llama-server --version 2>&1'
      The status should be success
      The output should be present
    End
  End

  Describe 'llama-bench'
    It 'is on PATH via symlink'
      When run command sh -c 'test -L /usr/bin/llama-bench'
      The status should be success
    End
  End
End
