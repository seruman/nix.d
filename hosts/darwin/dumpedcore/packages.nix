{
  localPackages,
  pkgsUnstable,
  username,
  ...
}:

{
  environment.systemPackages = [
    localPackages.gridcraft
    localPackages.markdown-preview
    localPackages.unfolder
  ];

  home-manager.users.${username}.home.packages = [
    pkgsUnstable.yt-dlp
  ];
}
