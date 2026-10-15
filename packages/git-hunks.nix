{
  fetchFromGitHub,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "git-hunks";
  version = "1.0.0-unstable-2026-05-13";

  src = fetchFromGitHub {
    owner = "rockorager";
    repo = "git-hunks";
    rev = "482baff749d3267f01a35bc27e08d949391cb3a4";
    hash = "sha256-0jUN9GDSK6AhkYJfQQv77mpa63Rh5jSDVIgNHNaQqyA=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 git-hunks "$out/bin/git-hunks"
    install -Dm644 git-hunks.1 "$out/share/man/man1/git-hunks.1"
    runHook postInstall
  '';

  meta = {
    description = "Non-interactive selective hunk staging for git";
    homepage = "https://github.com/rockorager/git-hunks";
    license = lib.licenses.mit;
    mainProgram = "git-hunks";
  };
}
