{ serumanDarwin, ... }:

{
  xdg.configFile."rex" = {
    source = "${serumanDarwin.filesRoot}/rex";
    recursive = true;
  };
}
