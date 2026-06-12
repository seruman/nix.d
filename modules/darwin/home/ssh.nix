{ ... }:

{
  home.file.".ssh/config.d/1password-agent".text = ''
    Include ~/.ssh/1Password/config

    Host *
      IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  '';
}
