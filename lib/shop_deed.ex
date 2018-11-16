defmodule ShopDeed do
  @moduledoc """
  Documentation for ShopDeed.
  """

  alias ShopDeed.{Deck, Decoder, DecodeError, Encoder, EncodeError}

  @doc """
  Returns the base64 encoded string as a Deck or a DecodeError.

  ## Examples

      iex> ShopDeed.decode("JWkTZX05uwGDCRV4XQGy3QGLmqUBg4GQJgGLGgO7AaABR3JlZW4vQmxhY2sgRXhhbXBsZQ__")
      {:error, %ShopDeed.DecodeError{message: "Must start with prefix: 'ADC'"}}

      iex> ShopDeed.decode("ADCJWkTZX05uwGDCRV4XQGy3QGLmqUBg4GQJgGLGgO7AaABR3JlZW4vQmxhY2sgRXhhbXBsZQ__")
      {:ok, %ShopDeed.Deck{cards: [
              %ShopDeed.Card{count: 2, id: 3000},
              %ShopDeed.Card{count: 1, id: 3001},
              %ShopDeed.Card{count: 3, id: 10091},
              %ShopDeed.Card{count: 3, id: 10102},
              %ShopDeed.Card{count: 3, id: 10128},
              %ShopDeed.Card{count: 3, id: 10165},
              %ShopDeed.Card{count: 3, id: 10168},
              %ShopDeed.Card{count: 3, id: 10169},
              %ShopDeed.Card{count: 3, id: 10185},
              %ShopDeed.Card{count: 1, id: 10223},
              %ShopDeed.Card{count: 3, id: 10234},
              %ShopDeed.Card{count: 1, id: 10260},
              %ShopDeed.Card{count: 1, id: 10263},
              %ShopDeed.Card{count: 3, id: 10322},
              %ShopDeed.Card{count: 3, id: 10354}
          ],
          heroes: [
              %ShopDeed.Hero{id: 4005, turn: 2},
              %ShopDeed.Hero{id: 10014, turn: 1},
              %ShopDeed.Hero{id: 10017, turn: 3},
              %ShopDeed.Hero{id: 10026, turn: 1},
              %ShopDeed.Hero{id: 10047, turn: 1}
          ],
          name: "Green/Black Example"}}
  """
  @spec decode(String.t()) :: {:ok, ShopDeed.Deck.t()} | {:error, DecodeError.t()}
  def decode(deck_string), do: Decoder.decode(deck_string)

  @spec decode!(String.t()) :: ShopDeed.Deck.t()
  def decode!(deck_string) do
    case decode(deck_string) do
      {:ok, deck} -> deck
      {:error, error} -> raise error
    end
  end

  @doc """
  Returns the given deck as a base64 encoded string compatable with playartifact.com's deck viewer.

  ## Examples

      iex> ShopDeed.encode(%ShopDeed.Deck{heroes: [], cards: [], name: "Green/Black Example"})
      ""

  """
  @spec encode(ShopDeed.Deck.t()) :: {:ok, String.t()} | {:error, EncodeError.t()}
  def encode(deck), do: Encoder.encode(deck)

  @spec encode!(Deck.t()) :: String.t()
  def encode!(deck) do
    case encode(deck) do
      {:ok, deck_string} -> deck_string
      {:error, error} -> raise error
    end
  end
end
