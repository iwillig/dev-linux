Describe 'Default shell'
  It 'is set to fish for new users'
    When run grep '^SHELL=/usr/bin/fish' /etc/default/useradd
    The status should be success
    The output should include '/usr/bin/fish'
  End
End

Describe 'Homebrew'
  It 'is cloned to /var/home/linuxbrew/.linuxbrew'
    When run sh -c '[ -d /var/home/linuxbrew/.linuxbrew ]'
    The status should be success
  End

  It 'is owned by the wheel group'
    When run sh -c 'stat -c "%G" /var/home/linuxbrew/.linuxbrew | grep -q wheel'
    The status should be success
  End
End

Describe 'SDKMAN'
  It 'is installed to /var/sdkman'
    When run sh -c '[ -d /var/sdkman ]'
    The status should be success
  End

  It 'has the sdkman-init script'
    When run sh -c '[ -f /var/sdkman/bin/sdkman-init.sh ]'
    The status should be success
  End

  It 'has fish integration at /etc/fish/functions/sdk.fish'
    When run sh -c '[ -f /etc/fish/functions/sdk.fish ]'
    The status should be success
  End
End

Describe 'Nyxt'
  It 'has its AppImage directory at /usr/lib/nyxt'
    When run sh -c '[ -d /usr/lib/nyxt ]'
    The status should be success
  End

  It 'is accessible from PATH via /usr/bin/nyxt symlink'
    When run sh -c '[ -L /usr/bin/nyxt ]'
    The status should be success
  End
End

Describe 'Systemd services'
  It '1Password installer service is enabled in multi-user.target'
    When run sh -c '[ -L /etc/systemd/system/multi-user.target.wants/install-1password.service ]'
    The status should be success
  End
End

Describe 'npm global tools'
  It 'are installed under /usr (not ~/.npm)'
    When run sh -c '[ -f /usr/bin/tsc ]'
    The status should be success
  End
End
