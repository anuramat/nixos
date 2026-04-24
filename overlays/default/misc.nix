inputs:
(final: prev: {

  protonmail-bridge = prev.protonmail-bridge.overrideAttrs (oldAttrs: {
    version = "unstable";
    src = inputs.protonmail-bridge;
    vendorHash = "sha256-aW7N6uacoP99kpvw9E5WrHaQ0fZ4P5WGsNvR/FAZ+cA=";
  });

})
