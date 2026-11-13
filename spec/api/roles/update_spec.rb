# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe "roles#update", type: :request do
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

  context "on membership role created long ago" do
    before { role.update_columns(created_at: 33.days.ago) }

    {
      group_id: -> { groups(:mitglieder_bw).id },
      type: -> { Group::Mitglieder::Zweitmitgliedschaft.sti_name },
      person_id: -> { people(:admin).id }
    }.each do |attribute, value|
      context "changing #{attribute}" do
        let(:payload) {
          {data: {id: role.id.to_s, type: "roles", attributes: {attribute => instance_exec(&value)}}}
        }

        it "is not allowed, otherwise the membership restrictions would need enforcing here" do
          expect {
            make_request
            expect(response.status).to eq(400), response.body
            expect(errors[0].code).to eq("unwritable_attribute")
          }.not_to change { role.reload.attributes }
        end
      end
    end

    context "changing start_on" do
      let(:payload) {
        {data: {id: role.id.to_s, type: "roles", attributes: {start_on: 1.day.ago.to_date.to_s}}}
      }

      it "is rejected by the membership restrictions" do
        expect {
          make_request
          expect(response.status).to eq(422), response.body
          expect(errors[0].attribute).to eq("start_on")
          expect(errors[0].code).to eq("membership_change_period_expired")
          expect(errors[0].message).to eq("kann nur innerhalb von 32 Tagen nach dem " \
            "Erfassen der Mitgliedschaft geändert werden")
        }.not_to change { role.reload.attributes }
      end
    end

    context "ending the role before the retroactive limit" do
      let(:payload) {
        {data: {id: role.id.to_s, type: "roles", attributes: {end_on: 33.days.ago.to_date.to_s}}}
      }

      it "is rejected by the membership restrictions" do
        expect {
          make_request
          expect(response.status).to eq(422), response.body
          expect(errors[0].attribute).to eq("end_on")
          expect(errors[0].code).to eq("too_far_in_past")
          expect(errors[0].message).to eq("darf höchstens 32 Tage in der Vergangenheit liegen")
        }.not_to change { role.reload.attributes }
      end
    end

    context "ending the role at a future date" do
      let(:payload) {
        {data: {id: role.id.to_s, type: "roles",
                attributes: {end_on: Date.current.end_of_year.to_s}}}
      }

      it "works" do
        expect {
          make_request
          expect(response.status).to eq(200), response.body
        }.to change { role.reload.end_on }.to(Date.current.end_of_year)
      end
    end
  end

  context "on recently created membership role" do
    let(:payload) {
      {data: {id: role.id.to_s, type: "roles", attributes: {start_on: 1.day.ago.to_date.to_s}}}
    }

    it "allows changing start_on" do
      expect {
        make_request
        expect(response.status).to eq(200), response.body
      }.to change { role.reload.start_on }.to(1.day.ago.to_date)
    end
  end

  context "on ended membership role" do
    let!(:active_role_making_person_readable) {
      Fabricate(Group::Stamm::Stammesbeauftragt.sti_name, group: groups(:adler), person:)
    }
    let(:payload) { {data: {id: role.id.to_s, type: "roles", attributes: {label: "Changed"}}} }

    before { role.update_columns(end_on: 10.days.ago, created_at: 1.year.ago) }

    it "is not found, otherwise the membership restrictions would need to cover ended roles" do
      expect {
        make_request
        expect(response.status).to eq(404), response.body
      }.not_to change { Role.with_inactive.find(role.id).attributes }
    end
  end
end
