# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe "self_registrations#create", type: :request do
  def jsonapi_headers
    super.merge("X-TOKEN" => token)
  end

  let(:service_token) { service_tokens(:permitted_root_token) }
  let(:token) { service_token.token }
  let(:group) { groups(:adler_mitglieder) }
  let!(:default_fee_kind) { fee_kinds(:baden_wuerttemberg_kind) }
  let!(:other_fee_kind) {
    Fabricate(:fee_kind, parent: fee_kinds(:top_fee_kind),
      layer: groups(:baden_wuerttemberg), name: "Other Fee Kind")
  }
  let!(:foerder_fee_kind) {
    Fabricate(:fee_kind, layer: groups(:root), name: "Förderbeitragsart",
      role_type: "Group::Mitglieder::Foerdermitgliedschaft")
  }

  before do
    group.update!(self_registration_role_type: Group::Mitglieder::OrdentlicheMitgliedschaft.name)

    service_token.update!(register_people: true, permission: :layer_and_below_full,
      layer_group_id: group.layer_group_id)
  end

  let(:payload) do
    {
      data: {
        type: "self_registrations",
        attributes: attributes
      }
    }
  end
  let(:attributes) {
    {
      first_name: "John",
      last_name: "Doe",
      nickname: "JD",
      email: "test@puzzle.ch",
      fee_kind_id: other_fee_kind.id
    }
  }

  subject(:make_request) do
    jsonapi_post "/api/groups/#{group.id}/self_registrations", payload
  end

  it "allows to manually set a fee kind" do
    expect {
      make_request
      expect(response.status).to eq(201), response.body
    }.to change { Role.count }.by(1)
    expect(Role.last.fee_kind_id).to eq(other_fee_kind.id)
  end

  context "if no fee kind id specified" do
    let(:attributes) {
      {
        first_name: "John",
        last_name: "Doe",
        nickname: "JD",
        email: "test@puzzle.ch"
      }
    }

    it "chooses a default fee kind" do
      expect {
        make_request
        expect(response.status).to eq(201), response.body
      }.to change { Role.count }.by(1)
      expect(Role.last.fee_kind_id).to eq(default_fee_kind.id)
    end
  end

  context "setting an invalid fee kind" do
    let(:attributes) {
      {
        first_name: "John",
        last_name: "Doe",
        nickname: "JD",
        email: "test@puzzle.ch",
        fee_kind_id: foerder_fee_kind.id
      }
    }

    it "falls back to default fee kind" do
      expect {
        make_request
        expect(response.status).to eq(201), response.body
      }.to change { Role.count }.by(1)
      expect(Role.last.fee_kind_id).to eq(default_fee_kind.id)
    end
  end

  context "with role type without fee kind" do
    before do
      group.update!(self_registration_role_type: Group::Mitglieder::Zweitmitgliedschaft.name)
    end

    context "if no fee kind id specified" do
      let(:attributes) {
        {
          first_name: "John",
          last_name: "Doe",
          nickname: "JD",
          email: "test@puzzle.ch"
        }
      }

      it "leaves fee kind at nil" do
        expect {
          make_request
          expect(response.status).to eq(201), response.body
        }.to change { Role.count }.by(1)
        expect(Role.last.fee_kind_id).to be_nil
      end
    end

    it "does not allow to manually set a fee kind" do
      expect {
        make_request
        expect(response.status).to eq(201), response.body
      }.to change { Role.count }.by(1)
      expect(Role.last.fee_kind_id).to be_nil
    end
  end
end
