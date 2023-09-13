defmodule Rivet.Utils.Test.UniformLogFormat do
  use ExUnit.Case, async: true
  alias Rivet.Utils.UniformLogFormat

  doctest Rivet.Utils.UniformLogFormat, import: true

  @timestamp {{2014, 12, 30}, {12, 6, 30, 100}}

  defp logfmt(a, b, d \\ []),
    do: UniformLogFormat.format(a, b, @timestamp, d) |> IO.iodata_to_binary()

  describe "format/4" do
    test "outputs basic string message correctly" do
      assert logfmt(:info, "basic string") == "2014-12-30 12:06:30.100 basic string\n"

      assert logfmt(:info, "basic string", key: "word") ==
               "2014-12-30 12:06:30.100 basic string - key=word\n"

      assert logfmt(:info, "", key: "word") == "2014-12-30 12:06:30.100 - key=word\n"
    end

    test "outputs supported basic metadata correctly" do
      assert logfmt(:info, "basic string", uid: 1, oid: 4, type: "test") ==
               "2014-12-30 12:06:30.100 basic string - uid=1 oid=4 type=test\n"
    end
  end

  describe "redact_sensitive/1" do
    test "removes password and key data from data-txt" do
      raw = [%{this: "fugly", password: "that", super_key: <<10, 11, 12>>, narf: 1}]
      expect = "[%{this: \"fugly\", password:*** super_key:*** narf: 1}]"

      assert UniformLogFormat.data2txt(raw) == expect
    end
  end
end
