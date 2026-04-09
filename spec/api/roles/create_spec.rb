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
  let!(:existing_role) {
    Fabricate(Group::Stamm::Stammesbeauftragt.name, person:,
      group: groups(:adler))
  }
  let!(:default_fee_kind) { fee_kinds(:baden_wuerttemberg_kind) }
  let!(:other_fee_kind) {
    Fabricate(:fee_kind, parent: fee_kinds(:top_fee_kind),
      layer: groups(:baden_wuerttemberg), name: "Other Fee Kind")
  }

  let(:payload) {
    {
      data: {
        type: "roles",
        attributes: {
          group_id: group.id,
          person_id: person.id,
          fee_kind_id: other_fee_kind.id,
          type: Group::Mitglieder::OrdentlicheMitgliedschaft.sti_name
        }
      }
    }
  }

  subject(:make_request) do
    jsonapi_post "/api/roles", payload
  end

  it "allows to manually set a fee kind" do
    expect {
      make_request
      expect(response.status).to eq(201), response.body
    }.to change { person.roles.count }.by(1)
  end

  context "if no fee kind id specified" do
    let(:payload) {
      {
        data: {
          type: "roles",
          attributes: {
            group_id: group.id,
            person_id: person.id,
            type: Group::Mitglieder::OrdentlicheMitgliedschaft.sti_name
          }
        }
      }
    }

    it "chooses a default fee kind" do
      expect {
        make_request
        expect(response.status).to eq(201), response.body
      }.to change { person.roles.count }.by(1)
      expect(person.roles.last.fee_kind_id).to eq(default_fee_kind.id)
    end
  end
end
