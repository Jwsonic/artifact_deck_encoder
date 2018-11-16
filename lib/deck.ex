defmodule ShopDeed.Card do
  defstruct id: 0, count: 0
end

defmodule ShopDeed.Hero do
  defstruct id: 0, turn: 0
end

defmodule ShopDeed.Deck do
  defstruct heroes: [], cards: [], name: ""
end
