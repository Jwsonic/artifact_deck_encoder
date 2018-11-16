defmodule ShopDeed.EncodeError do
  @type t :: %__MODULE__{message: String.t()}

  defexception [:message]

  def message(%{message: message}), do: message
end

defmodule ShopDeed.Encoder do
  use Bitwise

  alias ShopDeed.{Card, Constants, Deck, EncodeError}

  @spec encode(Deck.t()) :: {:error, EncodeError.t()} | {:ok, String.t()}
  def encode(%{cards: cards, heroes: heroes, name: name}) do
    version_byte = encode_version(heroes)
    name_bytes = encode_name(name)
    name_length_byte = encode_name_length(name)

    deck_bytes = encode_heroes(heroes) <> encode_cards(cards)
    checksum_byte = calculate_checksum(deck_bytes)

    merge_and_encode_bytes(version_byte, checksum_byte, name_length_byte, deck_bytes, name_bytes)
  end

  defp encode_version(heroes) do
    <<Constants.version()::4, 0::1, length(heroes)::3>>
  end

  defp encode_heroes(heroes) do
    heroes
    |> Enum.map(fn %{id: id, turn: turn} -> %Card{count: turn, id: id} end)
    |> encode_cards()
  end

  defp encode_cards(cards) do
    cards |> Enum.sort_by(fn %{id: id} -> id end) |> encode_cards(0, <<>>)
  end

  defp encode_cards([], _prev, bytes), do: bytes

  defp encode_cards([%Card{count: count, id: id} | rest], previous_id, bytes) do
    card_bytes = encode_card(count, id - previous_id)
    encode_cards(rest, id, bytes <> card_bytes)
  end

  defp encode_name(name) do
    name |> HtmlSanitizeEx.strip_tags() |> String.slice(0..62)
  end

  defp encode_name_length(name) do
    <<_::24, name_length::bits>> = <<String.length(name)::32>>
    name_length
  end

  defp calculate_checksum(bytes) do
    checksum = bytes |> :binary.bin_to_list() |> Enum.sum() &&& 0xFF

    <<checksum::8>>
  end

  defp merge_and_encode_bytes(
         version_byte,
         checksum_byte,
         name_length_byte,
         deck_bytes,
         name_bytes
       ) do
    bytes =
      Base.encode64(version_byte <> checksum_byte <> name_length_byte <> deck_bytes <> name_bytes)

    {:ok, Constants.prefix() <> bytes}
  end

  defp encode_card(count, id) do
    ""
  end

  defp extract_n_bits(value, num_bits) do
    limit = 1 <<< num_bits
    result = value &&& limit - 1

    case value >= limit do
      true -> result ||| limit
      false -> result
    end
  end

  defp add_remaining(value, already_written) do
    value = value >>> already_written

    bits = extract_n_bits(value, 7)

    <<>>
  end
end
