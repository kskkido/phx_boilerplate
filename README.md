# mix phx.new.boilerplate

phx.new with some modifications:
- Adds flake for otp/erlang and elixir as well as pnpm
- Adds package.json to assets opting for modules over vendor files
  - Generates esbuild.mjs file for bundling
  - Modifies app.css and app.js to reflect these changes

## Usage
Accepts the same arguments as phx.new. Does not support umbrella apps and tailwindcss must be included
```
mix phx.new.boilerplate project_path
```
## Building and installing archive
```
mix build // mix archive.build --include-dot-files
mix install // mix archive.install phx_boilerplate-0.1.0.ez
```
