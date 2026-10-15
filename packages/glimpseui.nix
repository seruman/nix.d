{
  buildNpmPackage,
  fetchFromGitHub,
  lib,
  nodejs,
  swift,
}:

buildNpmPackage (finalAttrs: {
  pname = "glimpseui";
  version = "0.8.1";

  src = fetchFromGitHub {
    owner = "hazat";
    repo = "glimpse";
    rev = "v${finalAttrs.version}";
    hash = "sha256-iiOLxg8UnsKPwqNV+zCLFoQZ78pypMr3WkesSf3nkc8=";
  };

  npmDepsHash = "sha256-UoP+RnbNdxBZWQ70c9B5UUWgAifxutz4ySVdAjDOylM=";
  forceEmptyCache = true;
  npmFlags = [ "--ignore-scripts" ];
  npmBuildScript = "build:macos";
  inherit nodejs;

  nativeBuildInputs = [ swift ];

  preInstall = ''
    # The package has no npm dependencies, so npm does not create node_modules.
    # npmInstallHook still expects it to exist when copying runtime deps.
    mkdir -p node_modules
  '';

  postInstall = ''
    # Upstream package.json.files excludes the generated native host.
    install -Dm755 src/glimpse "$out/lib/node_modules/glimpseui/src/glimpse"
  '';

  meta = {
    description = "Native micro Web UI for scripts and agents";
    homepage = "https://github.com/hazat/glimpse";
    license = lib.licenses.mit;
    mainProgram = "glimpseui";
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
    ];
  };
})
