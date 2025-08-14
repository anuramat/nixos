{ pkgs, lib }:
let
  hax = import ../../../hax/text.nix { inherit lib; };
in
{
  testFmt = {
    expr = hax.fmt "  line1\nline2\nline3  ";
    expected = [ "line1" "line2" "line3" ];
  };
  
  testFmtEmpty = {
    expr = hax.fmt "";
    expected = [ "" ];
  };
  
  testFmtSingleLine = {
    expr = hax.fmt "  single line  ";
    expected = [ "single line" ];
  };
  
  testPrependFrontmatterFull = {
    expr = hax.prependFrontmatter "content" { title = "Test"; author = "User"; };
    expected = ''
      ---
      author: User
      title: Test
      ---
      content'';
  };
  
  testPrependFrontmatterFiltered = {
    expr = hax.prependFrontmatter "content" { title = "Test"; author = null; date = "2024"; };
    expected = ''
      ---
      date: 2024
      title: Test
      ---
      content'';
  };
  
  testPrependFrontmatterEmpty = {
    expr = hax.prependFrontmatter "content" {};
    expected = ''
      ---
      
      ---
      content'';
  };
  
  testMkGlob = {
    expr = hax.mkGlob "*.log";
    expected = "--glob=!*.log";
  };
  
  testMkGlobComplex = {
    expr = hax.mkGlob "**/{target,node_modules}/**";
    expected = "--glob=!**/{target,node_modules}/**";
  };
}