#  frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe PersonResource, type: :resource do
  let(:user) { people(:stammesverwaltung) }

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
            payment_method: "debit",
            consent_data_retention: true,
            exit_date: "2025-12-12"
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
        .and change { person.payment_method }.to("debit")
        .and change { person.consent_data_retention }.to(true)
        .and change { person.exit_date }.to(Date.parse("2025-12-12"))
    end

    it "does not update write protected attributes" do
      payload[:data][:attributes][:entry_date] = "2025-01-01"

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
end
