{
  glide,
  stdenv,
}:

glide.packages.${stdenv.hostPlatform.system}.glide-browser-bin-unwrapped
