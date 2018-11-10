defmodule ShopDeed.Deck do
  defstruct heroes: [], cards: [], name: ""

  alias __MODULE__

  def validate(%Deck{heroes: _heroes, cards: _cards, name: _name}) do
    :ok
  end
end
