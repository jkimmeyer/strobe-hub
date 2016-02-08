defmodule Otis.Source.Test do
  def new(id) do
    %{ id: id }
  end
  def id(%{id: id}), do: id
  def open!(_source, _packet_size_bytes), do: []
  def close(_file, _source), do: nil
  def audio_type(_source), do: {"mp3", "audio/mpeg"}
  def metadata(_source), do: %Otis.Source.Metadata{}
end

defmodule Otis.SourceListTest do
  use   ExUnit.Case
  alias Otis.Source.Test, as: TS

  setup do
    sources = [
      TS.new("a"),
      TS.new("b"),
      TS.new("c"),
      TS.new("d"),
    ]
    id = Otis.uuid

    {:ok, list} = Otis.SourceList.from_list(id, sources)

    {:ok, id: id, sources: sources, source_list: list}
  end

  test "it gives each source a unique id", %{source_list: list} do
    {:ok, sources} = Otis.SourceList.list(list)
    ids = Enum.map sources, fn({id, _source}) -> id end
    assert length(Enum.uniq(ids)) == length(ids)
  end

  test "it gives new sources a unique id", %{source_list: list} do
    source = TS.new("e")
    {:ok, sources} = Otis.SourceList.list(list)
    l = length(sources)
    Otis.SourceList.append_source(list, source)
    {:ok, sources} = Otis.SourceList.list(list)
    ids = Enum.map sources, fn({id, _source}) -> id end
    assert length(Enum.uniq(ids)) == length(ids)
    assert length(ids) == l + 1
  end

  test "it gives new multiple sources unique ids", %{source_list: list} do
    new_sources = [TS.new("e"), TS.new("f")]
    {:ok, sources} = Otis.SourceList.list(list)
    l = length(sources)
    Otis.SourceList.append_sources(list, new_sources)
    {:ok, sources} = Otis.SourceList.list(list)
    ids = Enum.map sources, fn({id, _source}) -> id end
    assert length(Enum.uniq(ids)) == length(ids)
    assert length(ids) == l + 2
  end

  test "#next iterates the source list" do
    {:ok, a } = Otis.Source.File.new("test/fixtures/silent.mp3")
    {:ok, b } = Otis.Source.File.new("test/fixtures/snake-rag.mp3")
    {:ok, source_list} = Otis.SourceList.from_list(Otis.uuid, [a, b])

    {:ok, _uuid, source} = Otis.SourceList.next(source_list)
    %Otis.Source.File{path: path} = source

    assert path == Path.expand("../fixtures/silent.mp3", __DIR__)

    {:ok, _uuid, source} = Otis.SourceList.next(source_list)
    %Otis.Source.File{path: path} = source
    assert path == Path.expand("../fixtures/snake-rag.mp3", __DIR__)

    result = Otis.SourceList.next(source_list)
    assert result == :done
  end

  test "skips to next track", context do
    {:ok, sources} = Otis.SourceList.list(context.source_list)
    ids = Enum.map sources, fn({id, _source}) -> id end
    {:ok, id} = Enum.fetch ids, 0
    {:ok, 4} = Otis.SourceList.skip(context.source_list, id)
    {:ok, _id, source} = Otis.SourceList.next(context.source_list)
    assert source.id == "a"

    {:ok, id} = Enum.fetch ids, 1
    {:ok, 3} = Otis.SourceList.skip(context.source_list, id)
    {:ok, _id, source} = Otis.SourceList.next(context.source_list)
    assert source.id == "b"
  end

  test "can skip to a source id", context do
    {:ok, sources} = Otis.SourceList.list(context.source_list)
    ids = Enum.map sources, fn({id, _source}) -> id end
    {:ok, id} = Enum.fetch ids, 3
    {:ok, 1} = Otis.SourceList.skip(context.source_list, id)
    {:ok, _id, source} = Otis.SourceList.next(context.source_list)
    assert source.id == "d"
  end

  test "emits a state change event when appending a source", %{id: list_id} = context do
    :ok = Otis.State.Events.add_handler(MessagingHandler, self)

    source = TS.new("e")
    Otis.SourceList.append_source(context.source_list, source)
    {:ok, sources} = Otis.SourceList.list(context.source_list)
    {source_id, _} = List.last(sources)
    assert_receive {:new_source, ^list_id, 4, {^source_id, %{id: "e"}}}, 200

    Otis.State.Events.remove_handler(MessagingHandler, self)
    assert_receive :remove_messaging_handler, 100
  end

  test "emits a state change event when inserting a source", %{id: list_id} = context do
    :ok = Otis.State.Events.add_handler(MessagingHandler, self)

    source = TS.new("e")
    Otis.SourceList.insert_source(context.source_list, source, 0)
    {:ok, sources} = Otis.SourceList.list(context.source_list)
    {source_id, _} = List.first(sources)
    assert_receive {:new_source, ^list_id, 0, {^source_id, %{id: "e"}}}, 2000

    source = TS.new("f")
    Otis.SourceList.insert_source(context.source_list, source, -3)
    {:ok, sources} = Otis.SourceList.list(context.source_list)
    {source_id, _} = Enum.at(sources, -3)
    assert_receive {:new_source, ^list_id, 3, {^source_id, %{id: "f"}}}, 200

    Otis.State.Events.remove_handler(MessagingHandler, self)
    assert_receive :remove_messaging_handler, 200
  end

  # actually I don't think this is necessary -- the source change event emitted
  # by the broadcaster will do the required notification work -- the client can
  # skip to the source with the id given in that event.
  # test "emits a state change event when skipping sources"


  test "emits a state change event when cleared"
  test "emits a state change event when removing a source"
end


