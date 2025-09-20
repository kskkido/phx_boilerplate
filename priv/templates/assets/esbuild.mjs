// import * as path from "node:path";
import fs from "node:fs";
import * as esbuild from "esbuild";
import { copy as copyPlugin } from "esbuild-plugin-copy";
import postcss from "postcss";
import postcssFlexbugsFixes from "postcss-flexbugs-fixes";
import postcssFunctions from "postcss-functions";
import postcssImport from "postcss-import";
import postcssNested from "postcss-nested";
import postcssPresetEnv from "postcss-preset-env";
import postcssTailwind from "@tailwindcss/postcss";

const args = process.argv.slice(2);
const watch = args.includes("--watch");
const deploy = args.includes("--deploy");

// function resolveModulePath(pkg) {
// 	const rootPath = import.meta
// 		.resolve(pkg)
// 		.replace(/^file:\/\/(.+?\/node_modules)\/.+$/, "$1");
//
// 	return path.join(rootPath, pkg);
// }

const cssProcessor = postcss([
  postcssTailwind,
  postcssFlexbugsFixes,
  postcssImport,
  postcssNested,
  postcssPresetEnv({
    stage: 2,
  }),
  postcssFunctions({
    functions: {
      "--spacer": (value) => `calc(${value} * var(--size-spacer-1))`,
    },
  }),
]);

const options = {
  entryPoints: ["./js/app.js"],
  outdir: "../priv/static/assets",
  bundle: true,
  target: "es2015",
  logLevel: "info",
  nodePaths: ["../deps", process.env.NODE_PATH].filter(Boolean),
  plugins: [
    {
      name: "postcss",
      setup(build) {
        build.onLoad({ filter: /\.css$/ }, async (args) => {
          const css = await fs.promises.readFile(args.path, "utf8");
          const result = await cssProcessor.process(css, { from: args.path });

          return {
            contents: result.css,
            loader: "css",
            watchFiles: result.messages
              .filter((msg) => msg.type === "dependency")
              .map((msg) => msg.file),
          };
        });
      },
    },
    copyPlugin({
      assets: [
        {
          from: ["./media/**/*"],
          to: ["./media"],
        },
      ],
    }),
  ],
  define: {
    "process.env.NODE_ENV": JSON.stringify(
      deploy ? "production" : "development",
    ),
  },
  external: ["*.png", "*.svg", "*.jpg", "*.jpeg", "*.gif", "*.webp"],
};

if (deploy) {
  options.minify = true;
} else {
  options.sourcemap = true;
}
if (watch) {
  esbuild
    .context(options)
    .then((context) => context.watch())
    .catch(() => {
      process.exit(1);
    });
} else {
  esbuild.build(options).catch(() => {
    process.exit(1);
  });
}
