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
      :zahlungsart
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
    subject(:group) { groups(:adler) }

    it "has no abbreviations by default" do
      expect(group.abbreviations).to be_empty
    end

    it "accepts nested attributes to create abbreviations" do
      group.update!(abbreviations_attributes: [{value: "Adler"}, {value: "adl"}])

      expect(group.abbreviations.map(&:value)).to contain_exactly("adler", "adl")
    end

    it "accepts nested attributes to destroy abbreviations" do
      group.abbreviations.create!(value: "adl")
      abbreviation = group.abbreviations.first

      group.update!(abbreviations_attributes: [{id: abbreviation.id, _destroy: true}])

      expect(group.abbreviations).to be_empty
    end

    it "is destroyed together with its group" do
      association = Group::Stamm.reflect_on_association(:abbreviations)

      expect(association.options[:dependent]).to eq(:destroy)
    end
  end
end
