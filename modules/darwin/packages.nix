{
  localPackages,
  pkgs,
  pkgsUnstable,
  ...
}:

{
  programs._1password = {
    enable = true;
    package = pkgsUnstable._1password-cli;
  };

  environment.systemPackages = [
    localPackages.glide
    localPackages.sleeve
    localPackages.rex-terminfo
  ];

  environment.shells = [ pkgs.fish ];
  programs.fish.enable = true;
}
