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
    |> validate_checksum()
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
          <<version_and_heroes_byte::integer, checksum::integer, name_length::integer>> <> rest}
       ) do
    card_bytes_length = byte_size(rest) - name_length
    <<card_bytes::bytes-size(card_bytes_length)>> <> name_bytes = rest

    changeset
    |> put_change(:version, version_and_heroes_byte >>> 4)
    |> put_change(:hero_count, version_and_heroes_byte)
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
    computed_checksum =
      card_bytes
      |> String.codepoints()
      |> Enum.reduce(0, fn <<int::integer>>, sum -> sum + int end) &&& 0xFF

    case computed_checksum != checksum do
      true -> add_error(changeset, :bytes, "Checksum mistach #{checksum} != #{computed_checksum}")
      _ -> changeset
    end
  end
end
