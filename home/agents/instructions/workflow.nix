{ config, ... }:
let
  head = config.lib.agents.instructions.head;
in
{
  lib.agents.instructions.parts.workflow = ''
    You MUST adhere to the following two-stage development protocol:

    ${head} Stage 1: Test command identification

    Before starting ANY task you MUST explicitly identify a "test command". Examples
    of typical cases:

    - if there are any tests: you MUST run tests
    - nix flake: you MUST run `nix build`; `nix run` -- if applicable
    - minor proof-of-concept script -- you MUST demonstrate that it works

    When working on a big feature, you MUST write tests first (test-driven
    development).

    ${head} Stage 2: Dev-test loop

    You MUST repeat the "development" and "test" steps until you succeed:

    1. Development: implement the solution, a part of the solution, or fix a
       problem. You MUST NOT disable problematic features.
    2. Test: run the "testing command".
    3. If the task is not completed, or the "test command" fails, go to step 1.

    Only consider the task complete, when the "test command" succeeds.
  '';
}
