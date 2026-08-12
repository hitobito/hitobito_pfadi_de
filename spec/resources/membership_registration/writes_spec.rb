# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe MembershipRegistrationResource, type: :resource do
  def service_token(**opts)
    Fabricate(:service_token,
      opts.reverse_merge(
        layer: groups(:root),
        permission: :layer_and_below_full,
        groups: true,
        people: true,
        register_people: true
      ))
  end

  let(:group) { groups(:adler_mitglieder) }

  let(:payload) do
    {
      data: {
        type: "membership_registrations",
        attributes: {
          first_name: "Test",
          last_name: "User",
          email: "test@example.com",
          group_id: group.id,
          role_type: Group::Mitglieder::OrdentlicheMitgliedschaft.sti_name
        }
      }
    }
  end

  let(:instance) { MembershipRegistrationResource.build(payload) }

  describe "creating membership role" do
    let(:person) { Person.find_by(email: "test@example.com") }

    context "with create_membership_roles scope" do
      let(:token) { service_token(create_membership_roles: true) }
      let(:ability) { TokenAbility.new(token) }
      let(:membership_attrs) {
        {
          membership_application_reasons: "reason",
          membership_application_statement_stamm: "stamm statement",
          membership_application_statement_lv: "lv statement",
          membership_application_statement_bund: "bund statement",
          membership_application_process_data: "process data",
          membership_application_uuid: "2a4098f0-ae37-4726-842b-4720abfa9eaf"
        }
      }

      it "creates person with membership role" do
        expect {
          expect(instance.save).to eq(true), instance.errors.full_messages.to_sentence
        }.to change { Person.count }.by(1)
          .and change { Role.count }.by(1)
      end

      it "accepts membership attrs" do
        payload[:data][:attributes].merge!(membership_attrs)
        expect(instance.save).to eq(true), instance.errors.full_messages.to_sentence
        expect(person.attributes.symbolize_keys).to include(membership_attrs.merge)
      end
    end

    context "without create_membership_roles scope" do
      let(:token) { service_token(create_membership_roles: false) }
      let(:ability) { TokenAbility.new(token) }

      it "raises CanCan::AccessDenied" do
        expect { instance.save }.to raise_error(CanCan::AccessDenied)
      end
    end
  end
end
