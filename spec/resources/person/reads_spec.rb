#  frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe PersonResource, type: :resource do
  describe "serialization" do
    let!(:person) { people(:bottom_leader) }

    def serialized_attrs
      [
        :pronoun,
        :bank_account_owner,
        :iban,
        :bic,
        :bank_name,
        :payment_method,
        :consent_data_retention,
        :entry_date,
        :exit_date
      ]
    end

    before do
      params[:filter] = {id: {eq: person.id}}
    end

    it "works" do
      render

      data = jsonapi_data[0]

      expect(data.attributes.symbolize_keys.keys).to include(*serialized_attrs)

      serialized_attrs.each do |attr|
        expect(data.public_send(attr)).to eq(person.public_send(attr).as_json)
      end
    end
  end
end
