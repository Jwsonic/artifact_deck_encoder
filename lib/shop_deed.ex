defmodule ShopDeed do
  @moduledoc """
  Documentation for ShopDeed.
  """

  alias ShopDeed.Deck

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
    |> encode_remaining_heroes(3, heroes)
    |> encode_cards(heroes)

    ""
  end

  @doc """
  Returns the base64 encoded as a Deck.

  ## Examples

      iex> ShopDeed.decode("")
      %ShopDeed.Deck{heroes: [], cards: [], name: ""}

  """
  def decode(_code), do: %Deck{}

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

  defp encode_remaining_heroes({:error, error} = error, _already_written, _value), do: error

  defp encode_remaining_heroes(bytes, already_written, heroes) do
    add_remaining_number_to_buffer(bytes, already_written, length(heroes))
  end

  defp encode_cards({:error, _error} = error, _cards), do: error

  defp encode_cards(bytes, cards) do
    # TODO: start here
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
end
