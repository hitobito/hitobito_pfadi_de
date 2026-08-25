#  frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe GroupResource, type: :resource do
  before { allow(Graphiti.context[:object]).to receive(:current_scopes).and_return(["api"]) }

  describe "serialization" do
    let!(:group) { groups(:adler) }
    let!(:person) { people(:stammesverwaltung) }

    def serialized_attrs
      [
        :bank_account_owner,
        :iban,
        :bic,
        :bank_name,
        :gruendungsdatum,
        :aufloesungsdatum,
        :einsichtnahme_efz_durch_gruppe,
        :debitorennummer,
        :sepa_glaeubiger_id,
        :zahlungsart,
        :rechtsform,
        :strukturnummer,
        :stamm_typ,
        :opt_out_aufnahmeantrag,
        :opt_out_aufnahmeantrag_stammessuche,
        :efz_in_aufnahmeantrag,
        :eingeschraenkt,
        :gruendungsdatum,
        :aufloesungsdatum,
        :einsichtnahme_efz_durch_gruppe,
        :debitorennummer,
        :sepa_glaeubiger_id,
        :zahlungsart,
        :rechtsform,
        :strukturnummer,
        :stamm_typ,
        :opt_out_aufnahmeantrag,
        :opt_out_aufnahmeantrag_stammessuche,
        :efz_in_aufnahmeantrag,
        :eingeschraenkt
      ]
    end

    before do
      params[:filter] = {id: {eq: group.id}}
    end

    it "works" do
      render

      data = jsonapi_data[0]

      expect(data.attributes.symbolize_keys.keys).to include(*serialized_attrs)

      serialized_attrs.each do |attr|
        expect(data.public_send(attr)).to eq(group.public_send(attr).as_json)
      end
    end

    it "serializes abbreviations as an array of values" do
      group.abbreviations.create!(value: "Adler")

      render

      expect(jsonapi_data[0].abbreviations).to eq(["adler"])
    end

    it "serializes an empty array of abbreviations for a non-layer group" do
      params[:filter] = {id: {eq: groups(:pfadfinder).id}}

      render

      expect(jsonapi_data[0].abbreviations).to eq([])
    end
  end
end
