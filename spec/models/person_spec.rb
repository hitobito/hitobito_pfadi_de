# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe Person do
  let(:person) { people(:member) }

  subject { person }

  describe "entry_date" do
    before do
      person.roles.first.update(start_on: nil)
      person.roles.create!(type: person.roles.first.type, group: person.roles.first.group,
        start_on: "2025-12-31")
      person.roles.create!(type: person.roles.first.type, group: person.roles.first.group,
        start_on: "2020-08-01")
    end

    its(:entry_date) { should eq Date.parse("2020-08-01") }
  end

  describe "iban" do
    before { person.iban = "DE00 0000 0000" }

    it "is validated" do
      expect(person).not_to be_valid
      expect(person.errors[:iban]).to include(I18n.t("errors.messages.invalid_iban"))
    end
  end

  describe "zip_code" do
    it "validates with DE format by default" do
      person.zip_code = "10000"
      expect(person).to be_valid
      person.zip_code = "1000"
      expect(person).not_to be_valid
    end

    it "validates with country format if set" do
      person.country = "CH"
      person.zip_code = "10000"
      expect(person).not_to be_valid
      person.zip_code = "1000"
      expect(person).to be_valid
    end

    it "validates with DE country format if set" do
      person.country = "DE"
      person.zip_code = "10000"
      expect(person).to be_valid
      person.zip_code = "1000"
      expect(person).not_to be_valid
    end
  end
end
