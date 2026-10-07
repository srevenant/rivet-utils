defmodule Rivet.Utils.Module.PathChecker do
  @moduledoc """

  Rivet.Utils.Module.PathChecker.check("test", prefix: "Rivet.Utils")
  Rivet.Utils.Module.PathChecker.check("lib", no_exs: true, rules: :lib, prefix: "Rivet.Utils")
  Rivet.Utils.Module.PathChecker.fix("test", prefix: "Rivet.Utils")

  """

    @default_state %{
      fixer: &__MODULE__.noop_fixer/2,
      rules: :test,
      prefix: nil,
      filemods: %{}
    }

    def check(base \\ "test", opts \\ []) do
      state = Map.merge(@default_state, Map.new(opts))

      IO.puts("\n\n")

      Path.wildcard("#{base}/**/*.exs")
      |> Enum.reduce(state, &rules_for_exs/2)

      # ignore prior state, start over
      Path.wildcard("#{base}/**/*.ex")
      |> Enum.reduce(state, &rules_for_ex/2)

      IO.puts("\n\n")
    end

    # sugar
    def fix(path, opts \\ []), do: check(path, Keyword.put(opts, :fixer, &fix_defmod/2))

    ##############################################################################
    defp rules_for_exs(name, %{rules: :test} = state) do
      base = Path.basename(name, ".exs")

      cond do
        should_ignore?(base) -> state
        is_support?(base) -> stateful_log("EXS file found in support folder: #{name}", state)
        is_test?(base) -> check_test(name, state)
        is_migration?(base) -> check_migration(name, state)
        true -> stateful_log("SKIPPING #{name}", state)
      end
    end

    defp rules_for_exs(name, %{no_exs: true} = state),
      do: stateful_log("EXS file found: #{name}", state)

    defp rules_for_exs(path, state) do
      {_base, _mod, _filemod} = assess_fix_file(path, state)
      state
    end

    ##############################################################################
    defp rules_for_ex(name, %{rules: :test} = s) do
      cond do
        is_support?(name) -> check_support(name, s)
        is_migration?(name) -> stateful_log("EX file found in migrations folder: #{name}", s)
        is_test?(name) -> stateful_log("EX file found outside of support folder: #{name}", s)
        true -> stateful_log("EX file where it should be EXS, is it wrongly named? #{name}", s)
      end
    end

    defp rules_for_ex(path, state) do
      {_base, _mod, _filemod} = assess_fix_file(path, state)

      state
    end

    ##############################################################################
    defp check_migration(path, state) do
      {_base, mod, filemod} = assess_fix_file(path, nil)

      if Map.has_key?(state, filemod) do
        stateful_log("DUPLICATE MIGRATION #{path} vs #{state[mod]}", state)
      else
        put_in(state, [Access.key(:filemods, %{}), filemod], path)
      end
    end

    ##############################################################################
    defp check_support(path, state) do
      {base, _mod, _filemod} = assess_fix_file(path, state)

      if is_test?(base),
        do: IO.puts("FILE ENDS IN _test in support folder?: #{path}")

      state
    end

    ##############################################################################
    defp check_test(path, state) do
      {base, _mod, _filemod} = assess_fix_file(path, state)

      # doesn't end with test
      if not is_test?(base),
        do: IO.puts("TEST FILE DOES NOT END IN _test: #{path}")

      state
    end

    ##############################################################################
    defp index_rx(), do: ~r{/(index|model)$}
    defp strip_ts_rx(), do: ~r{/[0-9]+_}

    defp assess_fix_file(path, state) do
      {data, defmod} = module_from_defmodule(path)
      {base, pathmod} = module_from_path(path, state.prefix)

      if not should_ignore?(path) do
        check_dash(path, state)
        check_module_name(path, pathmod, defmod, data, state)
      end

      {base, pathmod, defmod}
    end

    defp check_module_name(path, pathmod, defmod, data, state) do
      if to_string(pathmod) != defmod do
        IO.puts("FILE/MODULE Mis-Match in #{path} Should be: #{pathmod} not #{defmod}")

        state.fixer.(:mod_name, path: path, old: defmod, new: pathmod, data: data)
      end
    end

    defp strip_special_names(path) do
      path =
        if Regex.match?(index_rx(), path),
          do: Regex.replace(index_rx(), path, ""),
          else: path

      if is_migration?(path),
        do: Regex.replace(strip_ts_rx(), path, "/"),
        else: path
    end

    defp module_from_defmodule(path) do
      {:ok, data} = File.read(path)

      [first | _] =
        String.split(data, "\n")
        |> Enum.reject(&String.starts_with?(&1, "#"))

      {data,
       first
       |> String.replace_prefix("defmodule ", "")
       |> String.replace_suffix(" do", "")}
    end

    defp module_from_path(path, prefix) do
      p =
        Path.rootname(path)
        |> strip_special_names()
        |> String.replace_prefix("lib/", "")

      modname = Transmogrify.Modulename.convert(p)
      modname = if is_nil(prefix), do: modname, else: "#{prefix}.#{modname}"

      {p, modname}
    end

    defp check_dash(path, state) do
      if String.contains?(path, "-") do
        IO.puts("NAME INCLUDES A DASH! #{path}")
        state.fixer.(:dash, path: path)
      end
    end

    ####
    def noop_fixer(_, _), do: :ok

    defp fix_defmod(:dash, _), do: :ok

    defp fix_defmod(:mod_name, opts) do
      opts = Map.new(opts)
      File.write(opts.path, Regex.replace(~r/#{opts.old}/, opts.data, opts.new))
    end

    ####
    defp is_test?(base), do: String.slice(base, -5..-1//1) == "_test"
    defp is_support?(p), do: String.contains?(p, "test/support")
    defp is_migration?(p), do: String.contains?(p, "repo/migration")

    defp should_ignore?(p), do: String.contains?(p, "test_helper")

    ##############################################################################
    # just for aesthetics
    defp stateful_log(msg, state) do
      IO.puts(msg)
      state
    end
  end
