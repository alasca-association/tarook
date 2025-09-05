{
  yk8s-test-lib,
  ctx,
  ...
}:
ctx.evaluator {
  inherit yk8s-test-lib;
  inherit (ctx) importPath;
  self = ctx.evaluator;
  path = ./.;
}
