# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe "roles#create", type: :request do
  def jsonapi_headers
    super.merge("X-TOKEN" => token)
  end

  let(:service_token) { service_tokens(:permitted_root_token) }
  let(:token) { service_token.token }
  let(:group) { groups(:adler_mitglieder) }
  let(:person) { Fabricate(:person) }
  let!(:role) { Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, person:, group:) }
  let!(:default_fee_kind) { fee_kinds(:baden_wuerttemberg_kind) }
  let!(:other_fee_kind) {
    Fabricate(:fee_kind, parent: fee_kinds(:top_fee_kind),
      layer: groups(:baden_wuerttemberg), name: "Other Fee Kind")
  }
  let(:payload) {
    {
      data: {
        id: role.id.to_s,
        type: "roles",
        attributes: {
          fee_kind_id: other_fee_kind.id.to_s
        }
      }
    }
  }

  subject(:make_request) do
    jsonapi_put "/api/roles/#{role.id}", payload
  end

  it "does not allow to manually set a fee kind" do
    expect {
      make_request
      expect(response.status).to eq(400), response.body
      expect(errors.length).to eq(1)
      expect(errors[0].attribute).to eq("data.attributes.fee_kind_id")
      expect(errors[0].code).to eq("unwritable_attribute")
      expect(errors[0].message).to eq("cannot be written")
    }.not_to change { role.reload.fee_kind_id }
  end

  context "if no fee kind id specified" do
    let(:payload) {
      {
        data: {
          id: role.id.to_s,
          type: "roles",
          attributes: {
            label: "unrelated change"
          }
        }
      }
    }

    it "works" do
      expect {
        make_request
        expect(response.status).to eq(200), response.body
      }.to change { role.reload.label }.to("unrelated change")
      expect(person.roles.last.fee_kind_id).to eq(default_fee_kind.id)
    end
  end
end
