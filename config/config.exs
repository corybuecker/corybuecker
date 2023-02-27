import Config

config :esbuild,
  version: "0.17.10",
  default: [
    args: ~w(
    js/highlight.ts
    js/analytics.ts
    --bundle
    --external:highlight.js/*
    --format=esm
    --minify
    --outdir=../output/js
  ),
    cd: Path.expand("../assets", __DIR__)
  ]

config :tailwind,
  version: "3.2.7",
  default: [
    args: ~w(
      --input=css/app.css
      --minify
      --output=../output/css/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]
