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
        :role_type
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
      expect(data.restricted).to be false
    end

    it "serializes restricted inherited from the root" do
      fee_kinds(:top_fee_kind).update!(restricted: true)

      render

      expect(fee_kind.restricted).to be_nil
      expect(jsonapi_data[0].restricted).to be true
    end

    context "as Landesmitgliederverwaltung" do
      let(:person) do
        Fabricate(:"Group::Landesverband::Landesmitgliederverwaltung",
          group: groups(:baden_wuerttemberg)).person
      end

      it "serializes restricted of sideloaded parents" do
        fee_kinds(:top_fee_kind).update!(restricted: true)
        params[:include] = "parent"

        render

        parent = d[0].sideload(:parent)
        expect(parent.id).to eq(fee_kinds(:baden_wuerttemberg_kind).id)
        expect(parent.restricted).to be true
      end
    end

    context "with a restricted fee kind of the Landesverband" do
      around do |example|
        Group::Landesverband.fee_kind_restrictable = true
        example.run
      ensure
        Group::Landesverband.fee_kind_restrictable = false
      end

      it "serializes restricted inherited from it" do
        fee_kinds(:baden_wuerttemberg_kind).update!(restricted: true)

        render

        expect(jsonapi_data[0].restricted).to be true
      end
    end
  end
end
