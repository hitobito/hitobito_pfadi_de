# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe PfadiDe::LayerGroup do
  let(:used_attrs) do
    [
      :gruendungsdatum,
      :aufloesungsdatum,
      :einsichtnahme_efz_durch_gruppe,
      :bank_account_owner,
      :iban,
      :bic,
      :bank_name,
      :debitorennummer,
      :sepa_glaeubiger_id,
      :zahlungsart,
      :abbreviations
    ]
  end

  shared_examples "layer group attrs" do
    it "has expected used attributes" do
      expect(described_class.used_attributes).to include(*used_attrs)
    end

    it "defines zahlungsart as i18n_enum" do
      expect(described_class.zahlungsart_labels).to eq(
        lastschrift: "Lastschrift",
        rechnung: "Rechnung"
      )
    end

    described_class.children.reject(&:layer?).each do |non_layer_class|
      it "#{non_layer_class} does not have attrs used on layer" do
        expect(non_layer_class.used_attributes).not_to include(*used_attrs)
      end
    end
  end

  describe Group::Stamm do
    it_behaves_like "layer group attrs"
  end

  describe Group::Bezirk do
    it_behaves_like "layer group attrs"
  end

  describe Group::Landesverband do
    it_behaves_like "layer group attrs"
  end

  describe Group::Bundesebene do
    it_behaves_like "layer group attrs"
  end

  describe "#abbreviations" do
    subject(:group) { Group::Stamm.new }

    it "is a superior attribute, only modifiable from above" do
      expect(Group::Stamm.superior_attributes).to include(:abbreviations)
    end

    it "normalizes a comma separated string into a downcased, unique array" do
      group.abbreviations = "Adler, adl,  , Adler"
      expect(group.abbreviations).to eq(%w[adler adl])
    end

    it "normalizes an array" do
      group.abbreviations = ["Adler", " adl ", ""]
      expect(group.abbreviations).to eq(%w[adler adl])
    end

    it "defaults to an empty array" do
      expect(group.abbreviations).to eq([])
    end

    it "is not a required field" do
      group.abbreviations = []
      group.valid?
      expect(group.errors[:abbreviations]).to be_empty
    end
  end

  describe "#abbreviations uniqueness across layers" do
    let(:stamm) { groups(:adler) }
    let(:other_layer) { groups(:baden_wuerttemberg) }

    it "is invalid if another layer already uses the same abbreviation" do
      other_layer.update!(abbreviations: ["adl"])
      stamm.abbreviations = ["ADL"]

      expect(stamm).not_to be_valid
      expect(stamm.errors[:abbreviations]).to be_present
    end

    it "is valid if no other layer uses the abbreviation" do
      stamm.abbreviations = ["adl"]

      expect(stamm).to be_valid
    end

    it "allows the group to keep its own abbreviation on update" do
      stamm.update!(abbreviations: ["adl"])
      stamm.name = "Adler Neu"

      expect(stamm).to be_valid
    end
  end
end
