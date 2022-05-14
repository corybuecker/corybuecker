import Config

config :esbuild,
  version: "0.14.39",
  default: [
    args:
      ~w(./js/analytics.js ./js/highlight.js --bundle --format=esm --outdir=../output/js --splitting),
    cd: Path.expand("../assets", __DIR__)
  ]

config :tailwind,
  version: "3.0.24",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../output/css/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]
