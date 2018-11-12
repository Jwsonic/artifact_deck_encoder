defmodule ShopDeed do
  @moduledoc """
  Documentation for ShopDeed.
  """

  alias ShopDeed.{Deck, DecodingDeck}

  use Bitwise, only_operators: true

  @encoder_version 2
  @encoder_prefix "ADC"
  @max_bytes_int 5
  @header_size 3

  @doc """
  Returns the given deck as a base64 encoded string compatable with playartifact.com's deck viewer.

  ## Examples

      iex> ShopDeed.encode(%ShopDeed.Deck{heroes: [], cards: [], name: "Green/Black Example"})
      ""

  """
  def encode(%Deck{heroes: heroes, cards: cards, name: name}) do
    # Encode name
    # Encode heroes
    # Encode cards

    name = clean_name(name)

    <<>>
    |> encode_hero_count(heroes)
    |> encode_name_len(name)
    |> encode_remaining_hero_count(3, heroes)
    |> encode_heroes(heroes)

    ""
  end

  @doc """
  Returns the base64 encoded as a Deck.

  ## Examples

      iex> ShopDeed.decode("JWkTZX05uwGDCRV4XQGy3QGLmqUBg4GQJgGLGgO7AaABR3JlZW4vQmxhY2sgRXhhbXBsZQ__")
      {:error, "Missing required prefix: #{@encoder_prefix}"}

  """
  def decode(@encoder_prefix <> code) do
    code
    |> decode_clean()
    |> decode_base64()
  end

  def decode(_code), do: {:error, "Missing required prefix: #{@encoder_prefix}"}

  ###########################
  # Private encoder functions
  ###########################

  defp clean_name(name) do
    name |> HtmlSanitizeEx.strip_tags() |> String.slice(0..63)
  end

  defp encode_hero_count(bytes, heroes) do
    count_bits = heroes |> length() |> extract_n_bits_with_carry(3)
    value = @encoder_version <<< 4 ||| count_bits

    add_byte(bytes, value)
  end

  defp encode_name_len({:error, _error} = error, _name), do: error
  defp encode_name_len(bytes, name), do: add_byte(bytes, length(name))

  defp encode_remaining_hero_count({:error, error} = error, _already_written, _value), do: error

  defp encode_remaining_hero_count(bytes, already_written, heroes) do
    add_remaining_number_to_buffer(bytes, already_written, length(heroes))
  end

  defp encode_heroes({:error, _error} = error, _cards), do: error

  defp encode_heroes(bytes, cards) do
    # TODO: start here when picking up encoding again
    cards |> Enum.sort_by(fn %{id: id} -> id end) |> Enum.reduce({bytes, 0}, fn x, acc -> nil end)
  end

  defp extract_n_bits_with_carry(value, num_bits) do
    limitBit = 1 <<< num_bits
    result = value &&& limitBit - 1

    if value >= limitBit do
      result ||| limitBit
    else
      result
    end
  end

  defp add_byte(_bytes, byte) when byte > 255, do: {:error, "Byte can't be larger than 255"}
  defp add_byte(bytes, byte), do: bytes <> <<byte::size(8)>>

  defp add_remaining_number_to_buffer(bytes, already_written, value) do
    value = value >>> already_written

    add_remaining_number_to_buffer(bytes, value)
  end

  defp add_remaining_number_to_buffer(bytes, value) when value > 0 do
    next_byte = extract_n_bits_with_carry(value, 7)
    bytes = bytes ++ [next_byte]
    value = value >>> 7

    add_remaining_number_to_buffer(bytes, value)
  end

  defp add_remaining_number_to_buffer(bytes, _value), do: bytes

  # defp add_card_to_buffer(bytes, )

  ###########################
  # Private decoder functions
  ###########################

  defp decode_clean(code) do
    code
    |> String.replace("-", "/")
    |> String.replace("_", "=")
  end

  defp decode_base64(code) do
    case Base.decode64(code) do
      :error -> {:error, "Unable to base64 decode string: #{code}"}
      success -> success
    end
  end

  defp parse_deck({:error, _msg} = error), do: error

  defp parse_deck({:ok, bytes}) do
    bytes
    |> DecodingDeck.changeset()
    |> DecodingDeck.version_and_hero(@encoder_version)
  end

  defp check_version(bytes) do
  end

  defp read_byte(<<byte::size(8)>> <> bytes), do: {:ok, byte, bytes}
  defp read_byte(_bytes), do: {:error, "No bytes left"}
end
