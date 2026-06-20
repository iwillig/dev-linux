Describe 'Sway — Wayland tiling WM'
  Describe 'sway'
    It 'is installed'
      When run command sh -c 'rpm -q sway'
      The status should be success
      The output should include 'sway'
    End
  End

  Describe 'swaylock'
    It 'is installed'
      When run command swaylock --version
      The status should be success
      The output should be present
    End
  End

  Describe 'swaybg'
    It 'is installed'
      When run command swaybg --version
      The status should be success
      The output should be present
    End
  End

  Describe 'swayidle'
    It 'is installed'
      When run command sh -c 'rpm -q swayidle'
      The status should be success
      The output should include 'swayidle'
    End
  End

  Describe 'xdg-desktop-portal-wlr'
    It 'is installed'
      When run command sh -c 'rpm -q xdg-desktop-portal-wlr'
      The status should be success
      The output should include 'xdg-desktop-portal-wlr'
    End
  End

  Describe 'waybar'
    It 'is installed'
      When run command waybar --version
      The status should be success
      The output should be present
    End
  End

  Describe 'wofi'
    It 'is installed'
      When run command sh -c 'rpm -q wofi'
      The status should be success
      The output should include 'wofi'
    End
  End

  Describe 'mako'
    It 'is installed'
      When run command sh -c 'rpm -q mako'
      The status should be success
      The output should include 'mako'
    End
  End

  Describe 'sway-config-fedora'
    It 'is installed'
      When run command sh -c 'rpm -q sway-config-fedora'
      The status should be success
      The output should include 'sway-config-fedora'
    End
  End

  Describe 'local config drop-in'
    It 'exists at /etc/sway/config.d/01-local.conf'
      When run command sh -c 'test -f /etc/sway/config.d/01-local.conf'
      The status should be success
    End

    It 'sets Inter as the sway font'
      When run command sh -c 'grep -q "font pango:Inter" /etc/sway/config.d/01-local.conf'
      The status should be success
    End

    It 'remaps Caps Lock to Control'
      When run command sh -c 'grep -q "ctrl:nocaps" /etc/sway/config.d/01-local.conf'
      The status should be success
    End
  End

  Describe 'GDM session integration'
    It 'installs a wayland session file for GDM'
      When run command sh -c 'test -f /usr/share/wayland-sessions/sway.desktop'
      The status should be success
    End

    # sway-config-fedora launches sway via its start-sway wrapper (env/logging
    # setup) rather than calling the sway binary directly.
    It 'session file declares the sway compositor'
      When run command sh -c 'grep -i "DesktopNames=sway" /usr/share/wayland-sessions/sway.desktop'
      The status should be success
      The output should include 'sway'
    End
  End
End
