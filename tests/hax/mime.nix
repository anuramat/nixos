{ pkgs, lib }:
let
  hax = import ../../hax/mime.nix { inherit lib; };

  # Mock package with desktop files
  mockPackage = pkgs.runCommand "mock-package" { } ''
    mkdir -p $out/share/applications

    # Desktop file with mime types
    cat >$out/share/applications/app1.desktop <<EOF
    [Desktop Entry]
    Name=App1
    MimeType=text/plain;text/html;application/pdf;
    Exec=app1
    EOF

    # Desktop file with different mime types
    cat >$out/share/applications/app2.desktop <<EOF
    [Desktop Entry]
    Name=App2
    MimeType=image/png;image/jpeg;
    Comment=Image viewer
    EOF

    # Desktop file without mime types
    cat >$out/share/applications/app3.desktop <<EOF
    [Desktop Entry]
    Name=App3
    Exec=app3
    EOF

    # Not a desktop file
    touch $out/share/applications/readme.txt
  '';

  # Mock file with mime types for generateMimeTypes file pattern
  mockMimeFile = pkgs.writeText "mimes.txt" ''
    application/json
    text/markdown
    image/svg+xml
  '';
in
{
  # Test mimeFromDesktop
  testMimeFromDesktop = {
    expr = hax.mimeFromDesktop mockPackage |> builtins.sort builtins.lessThan;
    expected = [
      "application/pdf"
      "image/jpeg"
      "image/png"
      "text/html"
      "text/plain"
    ];
  };

  # Test setMany
  testSetMany = {
    expr = hax.setMany "firefox" [
      "text/html"
      "application/pdf"
    ];
    expected = {
      "text/html" = "firefox";
      "application/pdf" = "firefox";
    };
  };

  # Test setMany with empty list
  testSetManyEmpty = {
    expr = hax.setMany "app" [ ];
    expected = { };
  };

  # Test generateMimeTypes with parts pattern
  testGenerateMimeTypesParts = {
    expr = hax.generateMimeTypes [
      {
        prefix = "image";
        suffixes = [
          "png"
          "jpeg"
          "gif"
        ];
      }
    ];
    expected = [
      "image/png"
      "image/jpeg"
      "image/gif"
    ];
  };

  # Test generateMimeTypes with exact pattern
  testGenerateMimeTypesExact = {
    expr = hax.generateMimeTypes [ "text/plain" ];
    expected = [ "text/plain" ];
  };

  # Test generateMimeTypes with exactList pattern
  testGenerateMimeTypesExactList = {
    expr = hax.generateMimeTypes [
      [
        "application/json"
        "application/xml"
      ]
    ];
    expected = [
      "application/json"
      "application/xml"
    ];
  };

  # Test generateMimeTypes with file pattern - disabled due to pure eval mode limitations
  # The file pattern expects a raw path, but in tests we get store paths which don't match the pattern

  # Test generateMimeTypes with mixed patterns
  testGenerateMimeTypesMixed = {
    expr =
      hax.generateMimeTypes [
        {
          prefix = "text";
          suffixes = [
            "plain"
            "html"
          ];
        }
        "application/pdf"
        [
          "image/png"
          "image/jpeg"
        ]
      ]
      |> builtins.sort builtins.lessThan;
    expected = [
      "application/pdf"
      "image/jpeg"
      "image/png"
      "text/html"
      "text/plain"
    ];
  };

  # Test generateMimeTypes with invalid pattern
  testGenerateMimeTypesInvalid = {
    expr = hax.generateMimeTypes [ { invalid = "pattern"; } ];
    expectedError.type = "ThrownError";
    expectedError.msg = "illegal pattern";
  };

  # Test complex mimeFromDesktop scenario
  testMimeFromDesktopComplex = {
    expr =
      let
        complexPackage = pkgs.runCommand "complex-package" { } ''
          mkdir -p $out/share/applications

          # Desktop file with duplicate mime types
          cat >$out/share/applications/dup.desktop <<EOF
          MimeType=text/plain;text/plain;application/pdf;
          MimeType=text/html;
          EOF
        '';
      in
      hax.mimeFromDesktop complexPackage |> builtins.sort builtins.lessThan;
    expected = [
      "application/pdf"
      "text/html"
      "text/plain"
    ];
  };

  # Test setMany preserves order as attrs
  testSetManyOrder = {
    expr =
      hax.setMany "editor" [
        "text/plain"
        "text/markdown"
        "text/html"
      ]
      |> builtins.attrNames
      |> builtins.sort builtins.lessThan;
    expected = [
      "text/html"
      "text/markdown"
      "text/plain"
    ];
  };
}
