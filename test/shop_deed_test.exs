defmodule ShopDeedTest do
  use ExUnit.Case
  doctest ShopDeed

  test "properly enocdes a deck into a string" do
  end

  test "properly decodes a deck from a string" do
    ShopDeed.DecodingDeck.changeset(
      "ADCJWYAIH1IJbwBoQEIeF0CIt0BCwMGAUcDAVcGAR8GHwYBCgEcNgEBBQ4QC0IvARY_"
    )
  end

  # prop decode(encode(deck)) == deck
  # prop all encoded decks start with "ADC"
end
