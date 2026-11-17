# facet: scores, culls and organises a photo library, with a web gallery (`facet-viewer`);
# the database and the weights in pretrained_models/ are relative to the working directory, and
# $FACET_CONFIG names the config, which defaults to the read-only shipped one
{ inputs, lib, ... }:
_final: prev:
let
  src = inputs.facet;
  inherit (lib.importTOML "${src}/pyproject.toml") project;

  client = prev.buildNpmPackage {
    pname = "facet-client";
    inherit (project) version;
    src = "${src}/client";
    nodejs = prev.nodejs_24;
    npmDepsHash = "sha256-nqZ+rKokuKmwUulg6D7Bd85bpEd0VlQeibEJ1U+vkVM=";
    env.NG_CLI_ANALYTICS = "false";
    # ng build compiles styles with sass-embedded's prebuilt dart binary
    nativeBuildInputs = [ prev.autoPatchelfHook ];
    preBuild = "autoPatchelf node_modules/sass-embedded-linux-*";
    installPhase = "cp -r dist/client/browser $out";
  };

  # 26.05's idna is too old for httpx2, and bumping it would rebuild most of the stack;
  # 3.13, since facet isn't tested on unstable's default 3.14
  unstable = import inputs.nixpkgs-unstable {
    inherit (prev) config;
    inherit (prev.stdenv.hostPlatform) system;
  };
  python = unstable.python313.override {
    self = python;
    packageOverrides = pfinal: psuper: {
      # config.rocmSupport (bgm5) would build both from source
      torch = psuper.torch.override { rocmSupport = false; };
      onnxruntime = psuper.onnxruntime.override (a: {
        onnxruntime = a.onnxruntime.override { rocmSupport = false; };
      });

      mcp-types = pfinal.buildPythonPackage rec {
        pname = "mcp_types";
        version = "2.3.0";
        pyproject = true;
        src = pfinal.fetchPypi {
          inherit pname version;
          hash = "sha256-0eRlSe2zXuGalJQPzubRrd1+WJq36pLdqD9dhHgfw2I=";
        };
        build-system = with pfinal; [
          hatchling
          uv-dynamic-versioning
        ];
        dependencies = with pfinal; [
          pydantic
          typing-extensions
        ];
        pythonImportsCheck = [ "mcp_types" ];
      };
      mcp =
        let
          # mcp 2 needs httpx2 >= 2.10, from the same monorepo as httpcore2; bumped here, since
          # in the package set they would rebuild starlette and everything above it; they want
          # uv-dynamic-versioning >= 0.14, but only for $UV_DYNAMIC_VERSIONING_BYPASS, which
          # 0.13 reads too
          bump =
            p:
            p.overridePythonAttrs (o: {
              version = "2.14.0";
              src = o.src.override { hash = "sha256-B3sLgMfJIzsM0gDVgvTEFeil0q7VG+xt0jgUcfPVU9w="; };
              pypaBuildFlags = [ "--skip-dependency-check" ];
            });
          httpx2 =
            (bump (psuper.httpx2.override { httpcore2 = bump psuper.httpcore2; })).overridePythonAttrs
              {
                # the websockets tests need starlette, whose tests need httpx2
                disabledTestPaths = [ "tests/httpx2/websockets" ];
              };
        in
        pfinal.buildPythonPackage rec {
          pname = "mcp";
          version = "2.3.0";
          pyproject = true;
          src = pfinal.fetchPypi {
            inherit pname version;
            hash = "sha256-ixR6UEQc8FnciMaE4K7tNofwqg85xs3nuQMw7/0rNNg=";
          };
          build-system = with pfinal; [
            hatchling
            uv-dynamic-versioning
          ];
          dependencies =
            with pfinal;
            [
              anyio
              httpx2
              jsonschema
              mcp-types
              opentelemetry-api
              pydantic
              pyjwt
              python-multipart
              sse-starlette
              starlette
              typing-extensions
              typing-inspection
              uvicorn
            ]
            ++ pyjwt.optional-dependencies.crypto;
          pythonImportsCheck = [ "mcp.server.mcpserver" ];
        };

      reverse-geocoder = pfinal.buildPythonPackage rec {
        pname = "reverse_geocoder";
        version = "1.5.1";
        pyproject = true;
        src = pfinal.fetchPypi {
          inherit pname version;
          hash = "sha256-Ki54G19pN22SK3j+iXjxNQyE/ODdsH4CyDTs+YtXx1w=";
        };
        build-system = [ pfinal.setuptools ];
        dependencies = with pfinal; [
          numpy
          scipy
        ];
        pythonImportsCheck = [ "reverse_geocoder" ];
      };

      # pyiqa backs the TOPIQ/LIQE scorers that every profile runs
      openai-clip = pfinal.buildPythonPackage rec {
        pname = "openai-clip";
        version = "1.0.1";
        pyproject = true;
        src = pfinal.fetchPypi {
          inherit pname version;
          hash = "sha256-zUC/LyBcCWxJUk/L/0hDOfeTtSr9bn/62Aov4QgVFyE=";
        };
        # pkg_resources is gone from setuptools 82
        postPatch = ''
          substituteInPlace clip/clip.py --replace-fail \
            'from pkg_resources import packaging' 'import packaging.version'
        '';
        build-system = [ pfinal.setuptools ];
        dependencies = with pfinal; [
          ftfy
          packaging
          regex
          torch
          torchvision
          tqdm
        ];
        pythonImportsCheck = [ "clip" ];
      };
      facexlib = pfinal.buildPythonPackage rec {
        pname = "facexlib";
        version = "0.3.0";
        pyproject = true;
        src = pfinal.fetchPypi {
          inherit pname version;
          hash = "sha256-eueEpSDrUuBVg+i/n2j3f0UIMjmsdU1kbWNQF7Sed2M=";
        };
        # setup.py reads the version it generates through locals(), which python 3.13 broke
        postPatch = "substituteInPlace setup.py --replace-fail \"locals()['__version__']\" \"'${version}'\"";
        build-system = with pfinal; [
          cython
          numpy
          setuptools
        ];
        dependencies = with pfinal; [
          filterpy
          numba
          numpy
          opencv-python
          pillow
          scipy
          torch
          torchvision
          tqdm
        ];
        pythonImportsCheck = [ "facexlib" ];
      };
      pyiqa = pfinal.buildPythonPackage rec {
        pname = "pyiqa";
        version = "0.1.16";
        pyproject = true;
        src = pfinal.fetchPypi {
          inherit pname version;
          hash = "sha256-gPuRMwJYWndIdcIktPlQaKwXvr2I9zWHbm8MO7CYjTQ=";
        };
        build-system = with pfinal; [
          setuptools
          setuptools-scm
        ];
        # training, dev tooling, the Q-Align comparison model; future is unused, and
        # unsupported on python >= 3.13
        pythonRemoveDeps = [
          "bitsandbytes"
          "datasets"
          "future"
          "pre-commit"
          "pytest"
          "ruff"
          "tensorboard"
        ];
        dependencies = with pfinal; [
          accelerate
          addict
          einops
          facexlib
          numpy
          openai-clip
          opencv-python-headless
          pandas
          pillow
          pyyaml
          requests
          scikit-image
          scipy
          sentencepiece
          timm
          torch
          torchvision
          tqdm
          transformers
          yapf
        ];
        pythonImportsCheck = [ "pyiqa" ];
      };
    };
  };

  facet-photo = python.pkgs.buildPythonPackage {
    pname = project.name;
    inherit (project) version;
    pyproject = true;
    inherit src;
    patches = [ ./pretrained-models-cwd.patch ];
    build-system = [ python.pkgs.setuptools ];
    # pyproject's dependencies and its `all` extra, plus torch, which it leaves to install.sh
    dependencies = with python.pkgs; [
      accelerate
      aiosqlite
      einops
      exifread
      fastapi
      hdbscan
      httpx
      imagecodecs
      imagehash
      insightface
      jsonschema
      kornia
      mcp
      numpy
      onnxruntime
      open-clip-torch
      opencv-python
      pillow
      pillow-heif
      psutil
      pyiqa
      pyjwt
      rawpy
      reverse-geocoder
      scipy
      send2trash
      sqlite-vec
      tifffile
      torch
      torchvision
      tqdm
      transformers
      uvicorn
      watchdog
      websockets
    ];
    # api/ serves the client from <install root>/client/dist/client/browser
    postInstall = ''
      mkdir -p $out/${python.sitePackages}/client/dist/client
      ln -s ${client} $out/${python.sitePackages}/client/dist/client/browser
    '';
    pythonImportsCheck = [
      "facet"
      "viewer"
      "api.agent.server"
    ];
  };
in
{
  # an env, so that the steps facet runs as `sys.executable facet.py ...` see the dependencies
  facet =
    (python.buildEnv.override {
      extraLibs = [ facet-photo ];
      makeWrapperArgs = [
        "--prefix PATH : ${lib.makeBinPath [ prev.exiftool ]}"
      ];
    }).overrideAttrs
      (o: {
        meta = o.meta // {
          mainProgram = "facet";
        };
      });
}
