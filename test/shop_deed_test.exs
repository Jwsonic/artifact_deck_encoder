defmodule ShopDeedTest do
  use ExUnit.Case
  doctest ShopDeed

  @g_b_deck "ADCJWkTZX05uwGDCRV4XQGy3QGLmqUBg4GQJgGLGgO7AaABR3JlZW4vQmxhY2sgRXhhbXBsZQ__"
  @u_r_g_deck "ADCJWYAIH1IJbwBoQEIeF0CIt0BCwMGAUcDAVcGAR8GHwYBCgEcNgEBBQ4QC0IvARY_"

  test "properly enocdes a deck into a string" do
  end

  test "properly decodes a deck from a string" do
    ShopDeed.decode(@u_r_g_deck)
  end

  test "encoded value equals decoded value" do
    assert @u_r_g_deck |> ShopDeed.decode!() |> ShopDeed.decode!() == @u_r_g_deck
    assert @g_b_deck |> ShopDeed.decode!() |> ShopDeed.decode!() == @g_b_deck
  end

  # prop decode(encode(deck)) == deck
  # prop all encoded decks start with "ADC"
end
