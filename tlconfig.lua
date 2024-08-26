return {
   build_dir = "build/src",
   source_dir = "src",
   include_dir = {
      "src/types",
      "src",
      "deps",
   },
   gen_target = "5.1",
   gen_compat = "required",
   dont_prune = {
      "*.toml",
      "*.hworld",
   }
}