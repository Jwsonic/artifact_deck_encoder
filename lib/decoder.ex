defmodule ShopDeed.DecodeError do
  @type t :: %__MODULE__{message: String.t()}

  defexception [:message]

  def message(%{message: message}), do: message
end

defmodule ShopDeed.Decoder do
  use Bitwise

  alias ShopDeed.{Card, Constants, Deck, DecodeError, Hero}

  @spec decode(String.t()) :: {:error, ShopDeed.DecodeError.t()} | {:ok, ShopDeed.Deck.t()}
  def decode(deck_string) do
    with {:ok, bytes} <- validate_prefix(Constants.prefix(), deck_string),
         {:ok, decoded_bytes} <- decode_bytes(bytes),
         {version, checksum, hero_count, card_bytes, name} <- split_bytes(decoded_bytes),
         :ok <- validate_version(Constants.version(), version),
         :ok <- validate_checksum(checksum, card_bytes) do
      {heroes, left_over_bytes} = read_heroes(card_bytes, hero_count)

      cards = read_cards(left_over_bytes)

      {:ok, %Deck{cards: cards, heroes: heroes, name: name}}
    else
      {:error, message} ->
        {:error, %DecodeError{message: message}}
    end
  end

  defp validate_prefix(expected_prefix, <<prefix::bytes-size(3)>> <> rest)
       when prefix == expected_prefix do
    {:ok, rest}
  end

  defp validate_prefix(expected_prefix, _bytes) do
    {:error, "Must start with prefix '#{expected_prefix}'"}
  end

  defp decode_bytes(bytes) do
    decoded =
      bytes
      |> String.replace("-", "/")
      |> String.replace("_", "=")
      |> Base.decode64()

    case decoded do
      :error -> {:error, "Unable to base64 decode string: #{bytes}"}
      ok -> ok
    end
  end

  defp split_bytes(
         <<version::4, _::1, hero_count::3, checksum::integer, name_length::integer>> <> rest
       ) do
    card_bytes_length = byte_size(rest) - name_length
    <<card_bytes::bytes-size(card_bytes_length)>> <> name_bytes = rest

    {version, checksum, hero_count, card_bytes, name_bytes}
  end

  defp validate_version(expected_version, version) when expected_version == version, do: :ok

  defp validate_version(_expected, version), do: {:error, "Version must be equal to #{version}"}

  defp validate_checksum(checksum, card_bytes) do
    calculated_checksum = card_bytes |> :binary.bin_to_list() |> Enum.sum() &&& 0xFF

    case calculated_checksum == checksum do
      false -> {:error, "Checksum mismatch"}
      true -> :ok
    end
  end

  defp read_heroes(bytes, count), do: read_heroes(bytes, count, 0, [])

  defp read_heroes(bytes, 0, _carry, cards), do: {cards, bytes}

  defp read_heroes(bytes, count, carry, heroes) do
    {%Card{count: turn, id: id}, rest} = read_card(bytes, carry)

    read_heroes(rest, count - 1, id, heroes ++ [%Hero{turn: turn, id: id}])
  end

  defp read_cards(bytes), do: read_cards(bytes, 0, [])

  defp read_cards("", _carry, cards), do: cards

  defp read_cards(bytes, carry, cards) do
    {card, rest} = read_card(bytes, carry)

    read_cards(rest, card.id, cards ++ [card])
  end

  defp read_card(<<count::2, _::6, _rest::bits>> = bytes, carry) do
    {id_info, rest} = read_encoded_32(bytes, 5)

    {%Card{
       id: id_info + carry,
       count: count + 1
     }, rest}
  end

  defp read_encoded_32(<<chunk::8, rest::bits>>, num_bits) do
    chunk |> read_chunk(num_bits) |> read_encoded_32(rest, 7, num_bits)
  end

  defp read_encoded_32({false, result}, rest, num_bits, _shift) when num_bits != 0 do
    {result, rest}
  end

  defp read_encoded_32({_continue, result}, <<chunk::8, rest::bits>>, num_bits, shift) do
    chunk |> read_chunk(num_bits, shift, result) |> read_encoded_32(rest, 7, shift + 7)
  end

  # Reads num_bits from bytes into out_bits, offset by the shift.
  defp read_chunk(bytes, num_bits, shift \\ 0, out_bits \\ 0) do
    continue_bit = 1 <<< num_bits
    # Wipe out all bits that don't concern us
    new_bits = bytes &&& continue_bit - 1

    # Prepend the newly read bits
    out_bits = out_bits ||| new_bits <<< shift
    continue = (bytes &&& continue_bit) != 0

    {continue, out_bits}
  end
end
