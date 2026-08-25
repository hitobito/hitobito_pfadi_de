# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe GroupAbbreviation do
  let(:stamm) { groups(:adler) }
  let(:other_layer) { groups(:baden_wuerttemberg) }

  subject(:abbreviation) { stamm.abbreviations.build(value: "Adler") }

  it "is valid with a present, unique value" do
    expect(abbreviation).to be_valid
  end

  it "requires a value" do
    abbreviation.value = ""

    expect(abbreviation).not_to be_valid
    expect(abbreviation.errors[:value]).to be_present
  end

  it "downcases and strips the value before validation" do
    abbreviation.value = "  Adler  "
    abbreviation.valid?

    expect(abbreviation.value).to eq("adler")
  end

  it "is invalid if another group already uses the same value, regardless of case" do
    other_layer.abbreviations.create!(value: "adl")
    abbreviation.value = "ADL"

    expect(abbreviation).not_to be_valid
    expect(abbreviation.errors[:value]).to be_present
  end

  it "renders its value with #to_s" do
    abbreviation.save!

    expect(abbreviation.to_s).to eq("adler")
  end
end
