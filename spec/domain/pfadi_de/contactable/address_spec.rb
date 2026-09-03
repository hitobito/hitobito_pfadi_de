# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe Contactable::Address do
  let(:contactable) do
    Group::Stamm.new(
      name: "Adler Gruppe",
      street: "Gruppenstrasse 10",
      zip_code: "10117",
      town: "Berlin",
      country: "DE"
    )
  end

  let(:efz_category) { contact_account_categories(:additional_address_group_efz_address) }

  describe "#efz_full_address_without_name" do
    it "returns the group address by default" do
      expect(Contactable::Address.new(contactable).efz_full_address_without_name)
        .to eq("Gruppenstrasse 10\n10117 Berlin\nDE")
    end

    it "returns the efz address when requested" do
      contactable.additional_addresses.build(
        street: "Efz Strasse 2",
        zip_code: "10115",
        town: "Efz Stadt",
        country: "DE",
        category: efz_category,
        uses_contactable_name: false,
        organization: true,
        organization_name: "Efz Empfänger"
      )

      expect(Contactable::Address.new(contactable, category_key: efz_category.key).efz_full_address_without_name)
        .to eq("Efz Strasse 2\n10115 Efz Stadt\nDE")
    end
  end

  describe "#efz_only_name" do
    it "returns the group name by default" do
      expect(Contactable::Address.new(contactable).efz_only_name).to eq("Adler Gruppe")
    end

    it "returns the efz address name when requested" do
      contactable.additional_addresses.build(
        street: "Efz Strasse 2",
        zip_code: "10115",
        town: "Efz Stadt",
        country: "DE",
        category: efz_category,
        uses_contactable_name: false,
        organization: true,
        organization_name: "Efz Empfänger"
      )

      expect(Contactable::Address.new(contactable, category_key: efz_category.key).efz_only_name)
        .to eq("Efz Empfänger")
    end
  end
end
