defmodule Chatlag.ReservedTest do
  use Chatlag.DataCase

  alias Chatlag.Reserved

  describe "words" do
    alias Chatlag.Reserved.Word

    @valid_attrs %{content: "some content"}
    @update_attrs %{content: "some updated content"}
    @invalid_attrs %{content: nil}

    def word_fixture(attrs \\ %{}) do
      {:ok, word} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Reserved.create_word()

      word
    end

    test "list_words/0 returns all words" do
      word = word_fixture()
      assert Reserved.list_words() == [word]
    end

    test "get_word!/1 returns the word with given id" do
      word = word_fixture()
      assert Reserved.get_word!(word.id) == word
    end

    test "create_word/1 with valid data creates a word" do
      assert {:ok, %Word{} = word} = Reserved.create_word(@valid_attrs)
      assert word.content == "some content"
    end

    test "create_word/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Reserved.create_word(@invalid_attrs)
    end

    test "update_word/2 with valid data updates the word" do
      word = word_fixture()
      assert {:ok, %Word{} = word} = Reserved.update_word(word, @update_attrs)
      assert word.content == "some updated content"
    end

    test "update_word/2 with invalid data returns error changeset" do
      word = word_fixture()
      assert {:error, %Ecto.Changeset{}} = Reserved.update_word(word, @invalid_attrs)
      assert word == Reserved.get_word!(word.id)
    end

    test "delete_word/1 deletes the word" do
      word = word_fixture()
      assert {:ok, %Word{}} = Reserved.delete_word(word)
      assert_raise Ecto.NoResultsError, fn -> Reserved.get_word!(word.id) end
    end

    test "change_word/1 returns a word changeset" do
      word = word_fixture()
      assert %Ecto.Changeset{} = Reserved.change_word(word)
    end
  end
end
