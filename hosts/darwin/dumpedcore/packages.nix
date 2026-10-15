{
  localPackages,
  pkgsUnstable,
  username,
  ...
}:

{
  environment.systemPackages = [
    localPackages.gridcraft
    localPackages.unfolder
  ];

  home-manager.users.${username}.home.packages = [
    pkgsUnstable.yt-dlp
  ];
}
