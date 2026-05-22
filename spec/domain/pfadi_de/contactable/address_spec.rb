# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe Contactable::Address do
  let(:address) { Contactable::Address.new(contactable) }

  let(:contactable) do
    Group::Stamm.new(
      name: "Adler Gruppe",
      street: "Gruppenstrasse 10",
      zip_code: "10117",
      town: "Berlin",
      country: "DE"
    )
  end

  it "#efz_full_address_without_name" do
    expect(address.efz_full_address_without_name).to eq("Gruppenstrasse 10\n10117 Berlin\nDE")
  end

  it "#efz_only_name" do
    expect(address.efz_only_name).to eq("Adler Gruppe")
  end
end
