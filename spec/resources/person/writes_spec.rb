#  frozen_string_literal: true

#  Copyright (c) 2025-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe PersonResource, type: :resource do
  let(:user) { people(:stammesverwaltung) }

  before { allow(Graphiti.context[:object]).to receive(:current_scopes).and_return(["api"]) }

  around do |example|
    RSpec::Mocks.with_temporary_scope do
      Graphiti.with_context(double({
        current_ability: Ability.new(user),
        entry: try(:person)
      })) { example.run }
    end
  end

  describe "updating" do
    let!(:user_role) { user.roles.first }
    let!(:person) { people(:member) }

    let(:payload) do
      {
        id: person.id.to_s,
        data: {
          id: person.id.to_s,
          type: "people",
          attributes: {
            pronoun: "sie/sie",
            bank_account_owner: "John Doe",
            iban: "CH93 0076 2011 6238 5295 7",
            bic: "DEUTDEFFXXX",
            bank_name: "Deutsche Bank",
            consent_data_retention: true
          }
        }
      }
    end

    let(:instance) do
      PersonResource.find(payload)
    end

    it "works" do
      expect {
        expect(instance.update_attributes).to eq(true)
      }.to change { person.reload.updated_at }
        .and change { person.pronoun }.to("sie/sie")
        .and change { person.bank_account_owner }.to("John Doe")
        .and change { person.iban }.to("CH93 0076 2011 6238 5295 7")
        .and change { person.bic }.to("DEUTDEFFXXX")
        .and change { person.bank_name }.to("Deutsche Bank")
        .and change { person.consent_data_retention }.to(true)
    end

    it "does not update write protected attributes" do
      payload[:data][:attributes][:entry_date] = "2025-01-01"

      expect { instance.update_attributes }.to raise_error(Graphiti::Errors::InvalidRequest)
    end

    it "does not update exit_date, a write protected attribute" do
      payload[:data][:attributes][:exit_date] = "2025-12-12"

      expect { instance.update_attributes }.to raise_error(Graphiti::Errors::InvalidRequest)
    end

    it "validates iban" do
      payload[:data][:attributes][:iban] = "12345678"

      expect {
        expect(instance.update_attributes).to eq(false)
      }.to not_change { person.reload.updated_at }
        .and not_change { person.iban }
    end
  end

  describe "sideposting" do
    let(:manager) { people(:bottom_leader) }
    let(:managed) { people(:member) }
    let(:person) { managed }
    let(:instance) { PersonResource.find(payload) }

    def payload_for(person, relationship, data, included = [])
      {
        id: person.id.to_s,
        data: {
          type: "people",
          id: person.id.to_s,
          attributes: {},
          relationships: {relationship => {data: data}}
        },
        included: included
      }
    end

    describe "people_managers" do
      describe "create" do
        let(:payload) do
          payload_for(managed, :people_managers,
            {type: "people_managers", "temp-id": "asdf", method: "create"},
            [{type: "people_managers", "temp-id": "asdf", attributes: {manager_id: manager.id}}])
        end

        it "works" do
          expect {
            expect(instance.update_attributes).to eq(true), instance.errors.full_messages.to_sentence
          }.to change { PeopleManager.count }.by(1)

          people_manager = PeopleManager.last
          expect(people_manager.manager).to eq manager
          expect(people_manager.managed).to eq managed
        end
      end

      describe "update" do
        let!(:people_manager) { PeopleManager.create!(manager: manager, managed: managed) }
        let(:other_manager) { Fabricate(:person) }
        let(:payload) do
          payload_for(managed, :people_managers,
            {type: "people_managers", id: people_manager.id.to_s, method: "update"},
            [{type: "people_managers", id: people_manager.id.to_s,
              attributes: {manager_id: other_manager.id}}])
        end

        it "raises AccessDenied" do
          expect { instance.update_attributes }.to raise_error(CanCan::AccessDenied)
          expect(people_manager.reload.manager).to eq manager
        end
      end

      describe "destroy" do
        let!(:people_manager) { PeopleManager.create!(manager: manager, managed: managed) }
        let(:payload) do
          payload_for(managed, :people_managers,
            {type: "people_managers", id: people_manager.id.to_s, method: "destroy"})
        end

        it "works" do
          expect {
            expect(instance.update_attributes).to eq(true), instance.errors.full_messages.to_sentence
          }.to change { PeopleManager.count }.by(-1)
        end
      end
    end

    describe "people_manageds" do
      describe "create" do
        let(:payload) do
          payload_for(manager, :people_manageds,
            {type: "people_managers", "temp-id": "asdf", method: "create"},
            [{type: "people_managers", "temp-id": "asdf", attributes: {managed_id: managed.id}}])
        end

        it "works" do
          expect {
            expect(instance.update_attributes).to eq(true), instance.errors.full_messages.to_sentence
          }.to change { PeopleManager.count }.by(1)

          people_manager = PeopleManager.last
          expect(people_manager.manager).to eq manager
          expect(people_manager.managed).to eq managed
        end
      end

      describe "update" do
        let!(:people_manager) { PeopleManager.create!(manager: manager, managed: managed) }
        let(:other_managed) { Fabricate(:person) }
        let(:payload) do
          payload_for(manager, :people_manageds,
            {type: "people_managers", id: people_manager.id.to_s, method: "update"},
            [{type: "people_managers", id: people_manager.id.to_s,
              attributes: {managed_id: other_managed.id}}])
        end

        it "raises AccessDenied" do
          expect { instance.update_attributes }.to raise_error(CanCan::AccessDenied)
          expect(people_manager.reload.managed).to eq managed
        end
      end
    end
  end
end
