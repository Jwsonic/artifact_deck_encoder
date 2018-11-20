defmodule ShopDeedTest do
  use ExUnit.Case
  doctest ShopDeed

  @g_b_deck "ADCJWkTZX05uwGDCRV4XQGy3QGLmqUBg4GQJgGLGgO7AaABR3JlZW4vQmxhY2sgRXhhbXBsZQ__"
  @u_r_g_deck "ADCJWYAIH1IJbwBoQEIeF0CIt0BCwMGAUcDAVcGAR8GHwYBCgEcNgEBBQ4QC0IvARY_"

  test "properly enocdes a deck into a string" do
    assert %ShopDeed.Deck{
             cards: [
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
             name: "Green/Black Example"
           }
           |> ShopDeed.encode!() == @g_b_deck
  end

  test "properly decodes a deck from a string" do
    assert ShopDeed.decode!(@g_b_deck) == %ShopDeed.Deck{
             cards: [
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
             name: "Green/Black Example"
           }
  end

  test "encoded value equals decoded value" do
    assert @u_r_g_deck |> ShopDeed.decode!() |> ShopDeed.decode!() == @u_r_g_deck
    assert @g_b_deck |> ShopDeed.decode!() |> ShopDeed.decode!() == @g_b_deck
  end

  # prop decode(encode(deck)) == deck
  # prop all encoded decks start with "ADC"
end
