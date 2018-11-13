defmodule ShopDeed.DecodingDeck do
  use Ecto.Schema
  use Bitwise, only_operators: true

  import Ecto.Changeset

  alias ShopDeed.Constants

  alias __MODULE__

  @primary_key false
  embedded_schema do
    field(:bytes, :binary)
    field(:total_bytes, :integer)
    field(:version_and_heroes_byte, :binary)
    field(:version, :integer)
    field(:hero_count, :integer)
    field(:checksum, :integer)
    field(:card_bytes, :binary)
    field(:name, :string)
    field(:prefix, :string)
  end

  def changeset(bytes) do
    %DecodingDeck{}
    |> cast(%{}, [])
    |> validate_prefix(bytes)
    |> clean_and_decode_bytes()
    |> split_bytes()
    |> validate_number(:version, equal_to: Constants.version())
    |> validate_number(:hero_count, greater_than: 0, less_than_or_equal_to: 5)
    |> validate_checksum()
    |> decode_heroes()
  end

  defp validate_prefix(changeset, <<prefix::bytes-size(3)>> <> rest = bytes) do
    case prefix == Constants.prefix() do
      true ->
        {put_change(changeset, :prefix, prefix), rest}

      _ ->
        {add_error(changeset, :prefix, "Must start with prefix '#{Constants.prefix()}'"), bytes}
    end
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

  defp split_bytes(
         {changeset,
          <<version::4, _::1, hero_count::3, checksum::integer, name_length::integer>> <> rest}
       ) do
    card_bytes_length = byte_size(rest) - name_length
    <<card_bytes::bytes-size(card_bytes_length)>> <> name_bytes = rest

    changeset
    |> put_change(:version, version)
    |> put_change(:hero_count, hero_count)
    |> put_change(:checksum, checksum)
    |> put_change(:card_bytes, card_bytes)
    |> put_change(:name, name_bytes)
  end

  defp validate_checksum(
         %Ecto.Changeset{
           changes: %{
             checksum: checksum,
             card_bytes: card_bytes
           },
           valid?: true
         } = changeset
       ) do
    computed_checksum = card_bytes |> :binary.bin_to_list() |> Enum.sum() &&& 0xFF

    case computed_checksum != checksum do
      true -> add_error(changeset, :bytes, "Checksum mistach #{checksum} != #{computed_checksum}")
      _ -> changeset
    end
  end

  defp decode_heroes(
         %Ecto.Changeset{
           changes: %{hero_count: hero_count, card_bytes: card_bytes}
         } = changeset
       ) do
    read_cards(card_bytes, hero_count) |> IO.inspect()

    changeset
  end

  defp read_encoded_32(<<chunk::8, rest::binary>>, num_bits) do
    chunk |> read_chunk(num_bits) |> read_encoded_32(rest, 7, num_bits)
  end

  defp read_encoded_32({false, result}, rest, num_bits, _shift) when num_bits != 0 do
    {result, rest}
  end

  defp read_encoded_32({_continue, result}, <<chunk::8, rest::binary>>, num_bits, shift) do
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

  defp read_cards(bytes, count), do: read_cards(bytes, count, 0, [])

  defp read_cards(_bytes, count, _carry, cards) when count == 0, do: cards

  # TODO: Implement with counts > 3
  # defp read_cards(
  #        <<card_count::2, _::1, id_info::5, rest::binary>>,
  #        count,
  #        carry,
  #        cards
  #      )
  #      when card_count == 3 do
  #   IO.inspect("Overflow on count #{count}")
  #   {id_info, rest} = read_encoded_32({true, id_info}, rest, 7, 5)
  #   id = id_info + carry
  #   new_count = count - 1

  #   new_cards =
  #     cards ++
  #       [
  #         %{
  #           id: id,
  #           count: card_count + 1
  #         }
  #       ]

  #   read_cards(rest, new_count, id, new_cards)
  # end

  defp read_cards(
         bytes,
         count,
         carry,
         cards
       ) do
    <<card_count::2, _::binary>> = bytes
    {id_info, rest} = read_encoded_32(bytes, 5) |> IO.inspect()
    id = id_info + carry

    new_cards =
      cards ++
        [
          %{
            id: id,
            count: card_count + 1
          }
        ]

    read_cards(rest, count - 1, id, new_cards)
  end
end
