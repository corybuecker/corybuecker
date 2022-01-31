---
title: Adding TailwindCSS, PostCSS, and optional plugins to a new Phoenix application
published: 2022-01-29T14:15:19-06
revised: 2022-01-30T06:28:07-06
preview: Adding a Node-based TailwindCSS + PostCSS pipeline that can be invoked from a Mix task.
description: Adding a Node-based TailwindCSS +PostCSS pipeline that can be invoked from a Mix task.
slug: adding-tailwindcss-postcss-optional-plugins-to-a-new-phoenix-application
---

The [Phoenix Framework](https://www.phoenixframework.org) ships with esbuild support out of the box. In fact, the default behavior is to invoke esbuild directly from a Mix task, powered by the [esbuild](https://github.com/phoenixframework/esbuild) package.

This allows me to compile my entire Javascript bundle with the following command:

```bash
mix esbuild default
```

Behind the scenes, the esbuild package uses a native esbuild binary. The binary includes the CSS loader by default, so this process will even extract my CSS from the Javascript.

```bash
➜  my_app mix esbuild default

  ../priv/static/assets/app.js   177.1kb
  ../priv/static/assets/app.css   13.5kb

⚡ Done in 10ms
```

The Phoenix team has also developed a [TailwindCSS package](https://hex.pm/packages/tailwind) that uses a similar native binary to add all Tailwind functionality to Phoenix applications. However, I want to take it a step further and use Tailwind as a PostCSS plugin. The biggest reason is that I want to add other PostCSS plugins to my CSS pipeline.

The first thing to do is bring in the tailwind package to `mix.exs`.

```elixir
defp deps do
  [
    {:phoenix, "~> 1.6.6"},
    ...,
    {:tailwind, "~> 0.1", runtime: Mix.env() == :dev}
  ]
end
```

Then I added the recommended configuration to `config.exs`.

```elixir
config :tailwind,
  version: "3.0.14",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]
```

Out of the box, I can use the tailwind package to compile my CSS. The package also uses sane content defaults for TailwindCSS's tree-shaking feature.

```bash
➜  my_app mix tailwind default

Done in 87ms.
```

Opening `priv/static/assets/app.css` will show the compiled CSS with only my required classes.

## 🛑 Is this enough?

Before going any further, this might be enough for most use-cases. TailwindCSS is designed to work with no preprocessing or plugins, and with less CSS overall. If PostCSS with plugins is not needed, then this approach works great as-is. All custom CSS can go in `app.css` underneath the tailwind imports.

## Node-based CSS pipeline

One use-case I want to support is breaking up my CSS files and using imports. This can be done with PostCSS and the [postcss-import plugin](https://github.com/postcss/postcss-import). For example, I cannot change my `app.css` file to the following:

```css
@import "tailwindcss/base";
@import "tailwindcss/components";
@import "tailwindcss/utilities";

@import "model/component";
```

The import of `model/component` will not be resolved by the TailwindCSS, since that is the responsibility of PostCSS.

The first thing I created was `assets/postcss.config.js` as:

```javascript
module.exports = {
  plugins: {
    "postcss-import": {},
    tailwindcss: {},
    autoprefixer: {},
  }
}
```

Then I removed the tailwind package and the changes to `config.exs`. The rest of the pipeline will be completely Node-based. Install all of the needed packages with NPM.

```bash
npm install -D tailwindcss autoprefixer postcss postcss-import @tailwindcss/forms
```

I added a script to `package.json` to make running the pipeline easier.

```javascript
{
  ...
  "scripts": {
    "compile": "cd assets && npx tailwind --postcss --config=tailwind.config.js --input=css/app.css --output=../priv/static/assets/app.css",
  }
}
```

Running `npm run compile` will now use the Node version with PostCSS and any plugins I want to include. One problem with this approach is that building my application in Docker requires adding a Node build layer to the Dockerfile. That hasn't been a big problem for me so far.

It's possible to hook the Node pipeline into Phoenix's watchers so that CSS is recompiled when changed. In `dev.exs`, update the watchers to:

```elixir
config :my_app, MyAppWeb.Endpoint,
  ...
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    npx: [
      "tailwind",
      "--postcss",
      "--config=tailwind.config.js",
      "--input=css/app.css",
      "--output=../priv/static/assets/app.css",
      cd: "assets"
    ]
  ]
```
