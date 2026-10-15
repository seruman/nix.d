{
  agent-browser,
  lib,
}:

assert lib.assertMsg (
  agent-browser.version == "0.27.0"
) "terminal-browser requires agent-browser 0.27.0";
agent-browser
