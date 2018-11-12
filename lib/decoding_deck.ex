defmodule ShopDeed.DecodingDeck do
  use Ecto.Schema
  use Bitwise, only_operators: true

  import Ecto.Changeset

  alias ShopDeed.Constants

  alias __MODULE__

  @decoder_prefix Constants.prefix()
  @decoder_version Constants.version()

  @primary_key false
  embedded_schema do
    field(:bytes, :binary)
    field(:total_bytes, :integer)
    field(:version_and_heroes, :binary)
  end

  def changeset(bytes) do
    %DecodingDeck{}
    |> cast(%{bytes: bytes, total_bytes: String.length(bytes)}, [:bytes, :total_bytes])
    |> validate_length(:bytes, min: 10)
    |> validate_prefix()
    |> validate_version()
  end

  defp clean_and_decode_bytes(%Ecto.Changeset{changes: %{bytes: bytes}} = changeset) do
    clean_bytes =
      bytes
      |> String.replace("-", "/")
      |> String.replace("_", "=")
      |> Base.decode64()

    case clean_bytes do
      :error -> add_error(changeset, :bytes, "Unable to base64 decode string: #{code}")
      {:ok, bytes} -> put_change(changeset, :bytes, bytes)
    end
  end

  defp validate_prefix(
         %Ecto.Changeset{changes: %{bytes: <<prefix::bytes-size(3)>> <> rest}} = changeset
       )
       when prefix == @decoder_prefix do
    put_change(changeset, :bytes, rest)
  end

  defp validate_prefix(changeset) do
    add_error(changeset, :bytes, "Must start with prefix '#{@decoder_prefix}'")
  end

  defp validate_version(
         %Ecto.Changeset{changes: %{bytes: <<version_and_heroes::integer>> <> rest}} = changeset
       )
       when version_and_heroes >>> 4 == @decoder_version do
    changeset |> put_change(:version_and_heroes, version_and_heroes) |> put_change(:bytes, rest)
  end

  defp validate_version(
         %Ecto.Changeset{
           changes: %{bytes: <<version_and_heroes::integer>> <> _rest}
         } = changeset
       ) do
    IO.inspect(version_and_heroes)
    add_error(changeset, :version_and_heroes, "Version mismatch: #{version_and_heroes >>> 4}")
  end
end
