defmodule ShopDeed.DecodeError do
  @type t :: %__MODULE__{message: String.t()}

  defexception [:message]

  def message(%{message: message}), do: message
end

defmodule ShopDeed.Decoder do
  use Ecto.Schema
  use Bitwise

  import Ecto.Changeset

  alias ShopDeed.{Card, Constants, Deck, DecodeError, Hero}

  alias __MODULE__

  @primary_key false
  embedded_schema do
    field(:name, :string)
    field(:cards, {:array, :map})
    field(:heroes, {:array, :map})

    field(:version, :integer)
    field(:hero_count, :integer)
    field(:checksum, :integer)
    field(:card_bytes, :binary)
    field(:prefix, :string)
  end

  def decode2(deck_string) do
    with {:ok, bytes} <- validate_prefix(Constants.prefix(), deck_string),
         cleaned_bytes <- clean_bytes(bytes),
         {:ok, decoded_bytes} <- Base.decode64(cleaned_bytes) do
      decoded_bytes
    else
      {:error, message} -> %DecodeError{message: message}
    end
  end

  def decode(deck_string) do
    %Decoder{}
    |> cast(%{}, [])
    |> validate_prefix(deck_string)
    |> clean_and_decode_bytes()
    |> split_bytes()
    |> validate_number(:version, equal_to: Constants.version())
    |> validate_number(:hero_count, greater_than: 0, less_than_or_equal_to: 5)
    |> validate_confirmation(:checksum, message: "Checksum does not match")
    |> decode_heroes()
    |> decode_cards()
    |> apply_action(:insert)
    |> process_result()
  end

  defp validate_prefix(expected_prefix, <<prefix::bytes-size(3)>> <> rest)
       when prefix == expected_prefix do
    {:ok, rest}
  end

  defp validate_prefix(expected_prefix, _bytes) do
    {:error, "Must start with prefix '#{expected_prefix}'"}
  end

  defp validate_prefix(changeset, <<prefix::bytes-size(3)>> <> rest = bytes) do
    case prefix == Constants.prefix() do
      true ->
        {put_change(changeset, :prefix, prefix), rest}

      _ ->
        {add_error(changeset, :prefix, "Must start with prefix '#{Constants.prefix()}'"), bytes}
    end
  end

  defp clean_bytes(bytes) do
    bytes
    |> String.replace("-", "/")
    |> String.replace("_", "=")
  end

  defp clean_and_decode_bytes({changeset, bytes}) do
    clean_bytes =
      bytes
      |> String.replace("-", "/")
      |> String.replace("_", "=")
      |> Base.decode64()

    case clean_bytes do
      :error -> {add_error(changeset, :bytes, "Unable to base64 decode string: #{bytes}"), bytes}
      {:ok, decoded_bytes} -> {changeset, decoded_bytes}
    end
  end

  defp split_bytes({%Ecto.Changeset{valid?: false} = changeset, _bytes}), do: changeset

  defp split_bytes(
         {changeset,
          <<version::4, _::1, hero_count::3, checksum::integer, name_length::integer>> <> rest}
       ) do
    card_bytes_length = byte_size(rest) - name_length
    <<card_bytes::bytes-size(card_bytes_length)>> <> name_bytes = rest

    card_bytes = :binary.bin_to_list(card_bytes)
    checksum_confirmation = Enum.sum(card_bytes) &&& 0xFF

    changeset
    |> put_change(:version, version)
    |> put_change(:hero_count, hero_count)
    |> put_change(:checksum, checksum)
    |> put_change(:checksum_confirmation, checksum_confirmation)
    |> put_change(:card_bytes, card_bytes)
    |> put_change(:name, name_bytes)
  end

  defp decode_heroes(%Ecto.Changeset{valid?: false} = changeset), do: changeset

  defp decode_heroes(
         %Ecto.Changeset{
           changes: %{hero_count: hero_count, card_bytes: card_bytes}
         } = changeset
       ) do
    {heroes, left_over_bytes} = read_heroes(card_bytes, hero_count)

    changeset |> put_change(:heroes, heroes) |> put_change(:card_bytes, left_over_bytes)
  end

  defp decode_cards(%Ecto.Changeset{valid?: false} = changeset), do: changeset

  defp decode_cards(
         %Ecto.Changeset{
           changes: %{card_bytes: card_bytes}
         } = changeset
       ) do
    cards = read_cards(card_bytes)

    put_change(changeset, :cards, cards)
  end

  defp process_result({:error, _stuff}), do: {:error, "Deck go boom"}

  defp process_result({:ok, %Decoder{name: name, heroes: heroes, cards: cards}}) do
    {:ok, %Deck{name: name, heroes: heroes, cards: cards}}
  end

  defp read_heroes(bytes, count), do: read_heroes(bytes, count, 0, [])

  defp read_heroes(bytes, 0, _carry, cards), do: {cards, bytes}

  defp read_heroes(bytes, count, carry, heroes) do
    {%Card{count: turn, id: id}, rest} = read_card(bytes, carry)

    read_heroes(rest, count - 1, id, heroes ++ [%Hero{turn: turn, id: id}])
  end

  defp read_cards(bytes), do: read_cards(bytes, 0, [])

  defp read_cards([], _carry, cards), do: cards

  defp read_cards(bytes, carry, cards) do
    {card, rest} = read_card(bytes, carry)

    read_cards(rest, card.id, cards ++ [card])
  end

  defp read_card([header | _rest] = bytes, carry) do
    {id_info, rest} = read_encoded_32(bytes, 5)

    {%Card{
       id: id_info + carry,
       count: (header >>> 6) + 1
     }, rest}
  end

  defp read_encoded_32([chunk | rest], num_bits) do
    chunk |> read_chunk(num_bits) |> read_encoded_32(rest, 7, num_bits)
  end

  defp read_encoded_32({false, result}, rest, num_bits, _shift) when num_bits != 0 do
    {result, rest}
  end

  defp read_encoded_32({_continue, result}, [chunk | rest], num_bits, shift) do
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
