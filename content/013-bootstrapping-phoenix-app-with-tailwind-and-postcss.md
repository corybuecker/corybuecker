---
title: Bootstrapping a new Phoenix application with Tailwind and PostCSS
published: 2022-01-29T14:15:19-06
preview: Adding a Node-based TailwindCSS pipeline that can be invoked from a Mix task.
description: Adding a Node-based TailwindCSS pipeline that can be invoked from a Mix task.
slug: bootstrapping-phoenix-app-with-tailwind-and-css
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
  version: "3.0.10",
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

One use-case I want to support is breaking up my CSS files and using imports. This can be done with PostCSS and the [postcss-import plugin](https://github.com/postcss/postcss-import). The native CLI version of TailwindCSS includes PostCSS support, but without plugins. For example, I cannot change my `app.css` file to the following:

```css
@import "tailwindcss/base";
@import "tailwindcss/components";
@import "tailwindcss/utilities";

@import "model/component";
```

The import of `model/component` will not be resolved by the TailwindCSS, since that is the responsbility of PostCSS.

The first thing I tried was creating `assets/postcss.config.js` as:

```javascript
module.exports = {
  plugins: {
    "postcss-import": {},
    tailwindcss: {},
    autoprefixer: {},
  }
}
```

I then updated the tailwind package configuration to:

```elixir
config :tailwind,
  version: "3.0.10",
  default: [
    args: ~w(
      --postcss
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]
```

Running the Mix task will result in an error because the `postcss-import` package cannot be found.

## Replacing the native TailwindCSS binary

I discovered the solution when I realized that the tailwind package supports an external path to the TailwindCSS CLI. I left the `tailwind.config.js` and `postcss.config.js` configuration files exactly as-is.

`tailwind.config.js`
```javascript
// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration
module.exports = {
  content: [
    './js/**/*.js',
    '../lib/*_web.ex',
    '../lib/*_web/**/*.*ex'
  ],
  theme: {
    extend: {},
  },
  plugins: [
    require('@tailwindcss/forms')
  ]
}
```

`postcss.config.js`
```javascript
module.exports = {
  plugins: {
    "postcss-import": {},
    tailwindcss: {},
    autoprefixer: {},
  }
}
```

Then I installed the TailwindCSS, PostCSS, and import plugin via NPM.

```bash
npm install -D postcss-import autoprefixer tailwindcss
```

I updated the tailwind package configuration to be:

```elixir
config :tailwind,
  path: Path.expand("../node_modules/.bin/tailwindcss", __DIR__),
  default: [
    args: ~w(
      --postcss
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]
```

Running `mix tailwind default` will now use the Node version with PostCSS and any plugins I want to include. One problem with this approach is that building my application in Docker requires adding a Node build layer to the Dockerfile. That hasn't been a big problem for me so far. An alternative approach is to drop the tailwind package completely and make a NPM-based pipeline. I really like being able to include TailwindCSS to the Phoenix watcher and recompile CSS in the same way that JS is recompiled.
