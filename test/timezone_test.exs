defmodule TimezoneTests do
  use ExUnit.Case, async: true

  test :get do
    %Timezone{:full_name => name, :standard_abbreviation => abbrev, :gmt_offset_std => offset} = Timezone.get("America/Chicago")
    assert name === "America/Chicago"
    assert abbrev === "CST"
    assert offset === -360
    %Timezone{:full_name => name, :gmt_offset_std => offset} = Timezone.get(:utc)
    assert name === "UTC"
    assert offset === 0
    %Timezone{:full_name => name, :gmt_offset_std => offset} = Timezone.get(2)
    assert name === "Etc/GMT+2"
    assert offset === +120
    %Timezone{:full_name => name, :gmt_offset_std => offset} = Timezone.get(-3)
    assert name === "Etc/GMT-3"
    assert offset === -180
    %Timezone{:standard_abbreviation => name, :gmt_offset_std => offset} = Timezone.get("CST")
    assert name === "CST"
    assert offset === -360
  end

  test :local do
    assert Timezone.local() !== nil
  end

  test :diff do
    utc = Timezone.get(:utc)
    cst = Timezone.get("America/Chicago")
    gmt_plus_two    = Timezone.get(2)
    gmt_minus_three = Timezone.get(-3) 
    # How many minutes do I apply to UTC when shifting to CST
    assert DateTime.from({{2014,2,24},{0,0,0}}, utc) |> Timezone.diff(cst) === -360
    # How many minutes do I apply to UTC when shifting to CDT
    assert DateTime.from({{2014,3,30},{0,0,0}}, utc) |> Timezone.diff(cst) === -300
    # And vice versa
    assert DateTime.from({{2014,2,24},{0,0,0}}, cst) |> Timezone.diff(utc) === 360
    assert DateTime.from({{2014,3,30},{0,0,0}}, cst) |> Timezone.diff(utc) === 300
    # How many minutes do I apply to gmt_plus_two when shifting to gmt_minus_three?
    assert DateTime.from({{2014,2,24},{0,0,0}}, gmt_plus_two) |> Timezone.diff(gmt_minus_three) === -300
    # And vice versa
    assert DateTime.from({{2014,2,24},{0,0,0}}, gmt_minus_three) |> Timezone.diff(gmt_plus_two) === 300
  end

  test :convert do
    utc = Timezone.get(:utc)
    cst = Timezone.get("America/Chicago")
    est = Timezone.get("America/New_York")
    gmt_plus_two    = Timezone.get(2)
    gmt_minus_three = Timezone.get(-3) 

    # If it's noon in CST, then it's 6'oclock in the evening in UTC
    date = %Date{year: 2014, month: 2, day: 24}
    time = %Time{hours: 12}
    assert %DateTime{:time => %Time{:hours => 18}} = %DateTime{date: date, time: time, timezone: cst} |> Timezone.convert(utc)
    # If it's noon in UTC, then it's 6'oclock in the morning in CST
    assert %DateTime{:time => %Time{:hours => 6}} = %DateTime{date: date, time: time, timezone: utc} |> Timezone.convert(cst)
    # If it's noon in CST, then it's 1'oclock in the afternoon in EST
    assert %DateTime{:time => %Time{:hours => 13}} = %DateTime{date: date, time: time, timezone: cst} |> Timezone.convert(est)
    # If it's noon in EST, then it's 11'oclock in the morning in CST
    assert %DateTime{:time => %Time{:hours => 11}} = %DateTime{date: date, time: time, timezone: est} |> Timezone.convert(cst)
    # If it's noon in GMT+2, then it's 7'oclock in the morning in GMT-3
    assert %DateTime{:time => %Time{:hours => 7}} = %DateTime{date: date, time: time, timezone: gmt_plus_two} |> Timezone.convert(gmt_minus_three)
    # If it's noon in GMT-3, then it's 5'oclock in the evening in GMT+2
    assert %DateTime{:time => %Time{:hours => 17}} = %DateTime{date: date, time: time, timezone: gmt_minus_three} |> Timezone.convert(gmt_plus_two)
  end

  test :parse_tzfile do
    # TZIF Version 1
    chicago = System.cwd |> Path.join("test/include/tzif/America/Chicago")
    assert {:ok, "CDT"} = chicago |> File.read! |> Timezone.Local.parse_tzfile(DateTime.from({{2014,3,24}, {0,0,0}}))
    assert {:ok, "CST"} = chicago |> File.read! |> Timezone.Local.parse_tzfile(DateTime.from({{2014,2,24}, {0,0,0}}))

    # TZIF Version 2
    chicago = System.cwd |> Path.join("test/include/tzif2/America/Chicago")
    assert {:ok, "CDT"} = chicago |> File.read! |> Timezone.Local.parse_tzfile(DateTime.from({{2014,3,24}, {0,0,0}}))
    assert {:ok, "CST"} = chicago |> File.read! |> Timezone.Local.parse_tzfile(DateTime.from({{2014,2,24}, {0,0,0}}))

    # TZIF Version 1
    new_york = System.cwd |> Path.join("test/include/tzif/America/New_York")
    assert {:ok, "EDT"} = new_york |> File.read! |> Timezone.Local.parse_tzfile(DateTime.from({{2014,3,24}, {0,0,0}}))
    assert {:ok, "EST"} = new_york |> File.read! |> Timezone.Local.parse_tzfile(DateTime.from({{2014,2,24}, {0,0,0}}))

    # TZIF Version 2
    new_york = System.cwd |> Path.join("test/include/tzif2/America/New_York")
    assert {:ok, "EDT"} = new_york |> File.read! |> Timezone.Local.parse_tzfile(DateTime.from({{2014,3,24}, {0,0,0}}))
    assert {:ok, "EST"} = new_york |> File.read! |> Timezone.Local.parse_tzfile(DateTime.from({{2014,2,24}, {0,0,0}}))
  end
end
