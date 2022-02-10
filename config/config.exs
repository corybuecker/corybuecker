import Config

config :esbuild,
  version: "0.14.0",
  default: [
    args: ~w(
      js/analytics.ts
      js/highlight.ts
      --bundle
      --minify
      --format=esm
      --splitting
      --target=es2020
      --outdir=../output/js
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

config :tailwind,
  version: "3.0.16",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --minify
      --verbose
      --input=css/app.css
      --output=../output/css/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]
