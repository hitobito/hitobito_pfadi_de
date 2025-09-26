#  frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe GroupResource, type: :resource do
  describe "serialization" do
    let!(:group) { groups(:adler) }
    let!(:person) { people(:stammesverwaltung) }

    def serialized_attrs
      [
        :bank_account_owner,
        :iban,
        :bic,
        :bank_name
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
  end
end
