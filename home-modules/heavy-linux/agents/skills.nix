{ inputs, ... }:
{
  lib.agents.skills = {
    explain-diff = {
      description = "explain a diff in a human-friendly way, so that the user can easily review it";
      text = ''
        Help me review this diff by providing a review guide:

        I will open it side by side with code, go through the review
        instructions top to bottom, and read mentioned files.

        Review instructions must be structured as a list of bullet points: each
        point must mention a few files and a short explanation of the changes.

        Order should be such that I can comfortably learn what changed in this
        diff, and incrementally build a mental model of the changes.


        After the bullet points, provide a concise summary of the changes.

        You must omit the changes to tests from the review guide. If there are
        files that only had tests changed/added/removed, you must list them in a
        separate list after the summary -- it should be a bullet point list of
        file names, with no explanations.
      '';
    };
    iterate-spec = {
      description = "refine feature specification/implementation plan/design document/SPEC.md/PLAN.md";
      text = ''
        Specification describes a feature that was not yet implemented. Your
        task is to review the specification and report to user. Do not edit the
        files.

        Identify and report:

        - ambiguities and contradictions in described feature behaviour
        - missing important edge cases
        - implicit contradictions with existing code behaviour or assumptions
        - behaviour that appears difficult to implement without major refactoring
        - inconsistent naming or terminology
        - anything else that is likely to cause problems in the future: bugs, maintainability issues, etc.

        Properties of a good spec:

        - internal consistency: spec should not contradict itself
        - consistency with existing code: spec should not make incorrect assumptions about existing behaviour
        - completeness of decription/deterministic result: there should be one obvious way to implement the spec
        - quality of the end result: resulting implementation should be maintainable and correct
      '';
    };
    rust = {
      description = "conventions for writing, testing and building Rust code; use whenever editing or creating a Rust project";
      files.template = inputs.self.templates.rust.path;
      text = ''
        ## code

        - in binary crates, instead of `pub(crate)`, you MUST use `pub`: nothing
          is exported from a binary, so the two are equivalent (`dead_code` still
          fires on unused `pub` items), and `(crate)` is just noise

        ## crates

        You SHOULD prefer these general-purpose crates over hand-written
        equivalents:

        - errors: `anyhow` for propagating errors with `.context()`; `thiserror`
          only for error enums that callers match on
        - derives: `derive_more` (`From`, `Display`, `Deref`, `Constructor`,
          ...), `derive-getters`, `smart-default` (`#[default = ...]` on fields),
          `strum` (enum <-> string, iteration over variants)
        - delegation and trait objects: `ambassador` (delegate trait impls to a
          field/variant), `dyn-clone` (`Clone` for `Box<dyn Trait>`), `typetag`
          (serde for trait objects), `inventory` (distributed static
          registration)
        - serde: `serde`, `serde_json`, `toml`, `serde_plain` (enum <-> plain
          string via serde), `schemars` (JSON schema from types)
        - async: `tokio`, `futures`, `tokio-stream`, `async-trait` (only for
          `dyn`-compatible async traits)
        - tests: `insta`, `similar-asserts` (see `## tests`)

        ## tests

        - you SHOULD try using snapshot tests using `insta` instead of manual assertions
          - if some parts of the snapshot are unstable (e.g. timestamps), use redactions
          - prefer `assert_yaml_snapshot!` over `assert_json_snapshot!`, unless you're specifically testing serialization to JSON
          - prefer inline snapshots over snapshot files
        - if snapshots are a bad fit, instead of the built-in `assert_eq!()` macro you MUST
          use `similar_asserts::assert_eq!()`; when possible, you MUST compare the
          entire struct at once, instead of checking field by field
        - test-only files MUST start with an inner `#![cfg(test)]`; the `mod`
          declaration in the parent stays unconditional
        - a normal file MUST contain at most one `#[cfg(test)]` item: a `mod tests`
          block at the end of the file
          - exception: test-only enum variants and their match arms are gated in place

        ## lints

        - the baseline is strict: most clippy groups, including `pedantic` and
          `nursery`, are enabled (groups need `priority = -1` so that individual
          lints can override them); lints that don't fit the project are
          allowed individually in `Cargo.toml`
        - the baseline is in `template/Cargo.toml`
        - you MUST fix warnings instead of silencing them; if a lint is wrong
          for the whole project, you SHOULD propose allowing it in `Cargo.toml`
          instead of adding local `#[allow]`s

        ## build

        - when building/testing, you MUST use `cargo ...` directly; if it's not
          available and the project has a flake, you MUST fall back to
          `nix develop -c cargo ...`

        ## new projects

        When creating a new Rust project, you SHOULD start from `template/` in
        this skill's directory: copy it (the files are read-only, so `chmod -R
        u+w` the copy), rename the package in `Cargo.toml`, and run `cargo
        generate-lockfile`. It contains:

        - `flake.nix`: crane build with dependencies cached separately, fenix
          stable toolchain, dev shell with `cargo-insta`, treefmt (`nix fmt`)
          run as a pre-commit hook
        - `Cargo.toml` and `clippy.toml` with the lint baseline, plus the test
          dev-dependencies
      '';
    };
  };
}
