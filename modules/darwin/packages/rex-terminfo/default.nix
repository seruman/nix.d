{ ncurses, runCommand }:

runCommand "rex-terminfo" { nativeBuildInputs = [ ncurses ]; } ''
  mkdir -p $out/share/terminfo
  tic -x -o $out/share/terminfo ${./xterm-rex.terminfo}
''
