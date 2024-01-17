# Used by "mix format"
locals_without_parens = [
  defcontract: 2
]

[
  locals_without_parens: locals_without_parens,
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  import_deps: [:ecto],
  export: [
    locals_without_parens: locals_without_parens
  ]
]
