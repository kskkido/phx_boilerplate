defmodule Mix.Tasks.Phx.New.Boilerplate do
  @moduledoc """
  phx.new with defaults. Does not support umbrella
  """

  use Mix.Task

  @switches [
    app: :string,
    umbrella: :boolean
  ]

  defmodule Context do
    defstruct [:app_name, :web_dirname]

    def new(app_name) do
      %__MODULE__{
        app_name: app_name,
        web_dirname: "#{app_name}_web"
      }
    end
  end

  @impl Mix.Task
  def run([app_name | argv]) do
    argv
    |> OptionParser.parse(strict: @switches)
    |> then(fn {opts, argv, _} ->
      cond do
        Keyword.get(opts, :umbrella, false) ->
          Mix.raise("Umbrella apps are unsupported")

        true ->
          Mix.Task.load_all()
          generate(app_name, argv, opts)
      end
    end)
  end

  def run([]) do
    Mix.raise("Please provide a path, e.g., mix phx.new.boilerplate my_app")
  end

  defp generate(project_path, argv, opts) do
    Mix.Task.run("phx.new", [project_path | argv])
    File.cd!(project_path)
    app_name = opts[:app] || project_path |> Path.expand() |> Path.basename()
    context = Context.new(app_name)
    edit_mix()
    edit_config()
    edit_dev_configs()
    write_templates(context)
    edit_root_layout(context)
    Mix.shell().info("""
    Next steps:

        $ cd <project>
        $ git add .
        $ direnv allow
        $ rm -rf _build ; mix deps.get ; mix deps.compile
        $ mix ecto.setup
        $ mix assets.deps
        $ mix phx.server

    """)
  end

  defp edit_mix() do
    "mix.exs"
    |> File.read!()
    |> Code.string_to_quoted!()
    |> Macro.prewalk(fn
      {:defp = operator, meta, [{:deps, _, _} = fun_head, [do: deps]]} ->
        deps
        |> Enum.reject(fn
          {_, _, [name | _]} when name in [:esbuild, :tailwind] -> true
          _ -> false
        end)
        |> then(&{operator, meta, [fun_head, [do: &1]]})

      {:defp = operator, meta, [{:aliases, _, _} = fun_head, [do: aliases]]} ->
        aliases
        |> Enum.reject(fn
          {alias, _} ->
            alias
            |> Atom.to_string()
            |> String.starts_with?("assets.")

          _ ->
            false
        end)
        |> Enum.concat([
          quote do
            {:"assets.deps", ["cmd --cd assets pnpm i"]}
          end,
          quote do
            {:"assets.check", ["cmd --cd assets pnpm check --fix"]}
          end,
          quote do
            {:"assets.setup", ["cmd --cd assets pnpm i"]}
          end,
          quote do
            {:"assets.build",
             ["cmd --cd assets NODE_PATH=#{Mix.Project.build_path()} pnpm build:prod"]}
          end,
          quote do
            {:"assets.deploy",
             [
               "cmd --cd assets NODE_PATH=#{Mix.Project.build_path()} pnpm build:prod",
               "phx.digest"
             ]}
          end
        ])
        |> then(&{operator, meta, [fun_head, [do: &1]]})

      rest ->
        rest
    end)
    |> Macro.to_string()
    |> then(&File.write!("mix.exs", &1))
  end

  defp edit_config() do
    "config/config.exs"
    |> File.read!()
    |> Code.string_to_quoted!()
    |> then(fn {operator, meta, arguments} ->
      arguments
      |> Enum.reject(fn
        {_, _, [name | _]} when name in [:esbuild, :tailwind] -> true
        _ -> false
      end)
      |> then(&{operator, meta, &1})
    end)
    |> Macro.to_string()
    |> then(&File.write("config/config.exs", &1))
  end

  defp edit_dev_configs() do
    "config/dev.exs"
    |> File.read!()
    |> Code.string_to_quoted!()
    |> Macro.prewalk(fn
      {:watchers = operator, arguments} ->
        arguments
        |> Enum.reject(fn
          {name, _} when name in [:esbuild, :tailwind] -> true
          _ -> false
        end)
        |> Enum.concat([
          quote do
            {:pnpm,
             [
               "build:dev:watch",
               cd: Path.expand("../assets", __DIR__),
               env: [{"NODE_PATH", Mix.Project.build_path()}]
             ]}
          end
        ])
        |> then(&{operator, &1})

      rest ->
        rest
    end)
    |> Macro.to_string()
    |> then(&File.write!("config/dev.exs", &1))
  end

  defp write_templates(%{app_name: app_name, web_dirname: web_dirname}) do
    Enum.each(
      [
        {:file, {:static, "flake.nix"}},
        {:file, {:static, ".envrc"}},
        {:file, {:static, "assets/package.json"}},
        {:file, {:static, "assets/biome.json"}},
        {:file, {:static, "assets/esbuild.mjs"}},
        {:file, {:template, "assets/css/app.css.eex", "assets/css/app.css"}},
        {:file, {:template, "assets/js/app.js.eex", "assets/js/app.js"}},
        {:directory, "assets/media"}
      ],
      fn
        {:file, {:static, path}} ->
          path
          |> Path.expand(templates_directory())
          |> Mix.Generator.copy_file(path)

        {:file, {:template, source, target}} ->
          source
          |> Path.expand(templates_directory())
          |> then(
            &Mix.Generator.create_file(
              target,
              EEx.eval_file(&1,
                app_name: app_name,
                web_dirname: web_dirname
              )
            )
          )

        {:directory, path} ->
          Mix.Generator.create_directory(path)
      end
    )
  end

  defp edit_root_layout(%{web_dirname: web_dirname}) do
    "lib/#{web_dirname}/components/layouts/root.html.heex"
    |> then(fn filepath ->
      filepath
      |> File.read()
      |> map_result(&{filepath, &1})
    end)
    |> bind_result(fn {filepath, content} ->
      content
      |> then(&Regex.replace(~r/assets\/css\/app.css/, &1, "assets\/app.css"))
      |> then(&Regex.replace(~r/assets\/js\/app.js/, &1, "assets\/app.js"))
      |> then(&File.write(filepath, &1))
    end)
    |> case do
      :ok -> :ok
      {:error, message} -> Mix.raise("Failed to edit root layout component: #{message}")
    end
  end

  defp map_result(result, func), do: bind_result(result, &{:ok, func.(&1)})

  defp bind_result({:ok, value}, func), do: func.(value)

  defp bind_result(error, _), do: error

  defp templates_directory do
    Path.expand("templates", :code.priv_dir(:phx_boilerplate))
  end
end
