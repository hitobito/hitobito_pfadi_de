# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe FeeKindResource, type: :resource do
  let(:group) { groups(:adler) }
  let(:person) do
    Fabricate(:"Group::Stamm::Stammesschatzmeister", group: group).person
  end

  let!(:fee_kind) do
    Fabricate(
      :fee_kind,
      parent: fee_kinds(:baden_wuerttemberg_kind),
      layer: group
    )
  end

  describe "serialization" do
    def serialized_attrs
      [
        :name,
        :layer_id,
        :parent_id,
        :role_type,
        :restricted
      ]
    end

    before do
      params[:filter] = {layer_id: {eq: group.id}}
    end

    it "works" do
      render

      data = jsonapi_data[0]

      expect(data.jsonapi_type).to eq("fee_kinds")
      expect(data.id).to eq(fee_kind.id)

      expect(data.attributes.symbolize_keys.keys).to include(*serialized_attrs)

      serialized_attrs.each do |attr|
        expect(data.public_send(attr)).to eq(fee_kind.public_send(attr).as_json)
      end
    end
  end
end
