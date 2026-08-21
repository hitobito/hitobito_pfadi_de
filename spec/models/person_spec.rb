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
    let(:group) { groups(:adler_mitglieder) }
    let(:fee_kind) { fee_kinds(:baden_wuerttemberg_kind) }

    # the :member fixture otherwise already has an active Ordentliche
    # Mitgliedschaft (roles(:paying_member)), which would count as a
    # membership role and conflict with the ones created below
    before { roles(:paying_member).destroy }

    it "is nil without membership roles" do
      expect(person.entry_date).to be_nil
    end

    it "ignores non-membership roles" do
      person.roles.create!(type: person.roles.first.type, group: person.roles.first.group,
        start_on: "2020-08-01")
      expect(person.entry_date).to be_nil
    end

    it "is the start date of the earliest membership role" do
      foerder_fee_kind = Fabricate(:fee_kind, layer: Group.roots.first,
        role_type: Group::Mitglieder::Foerdermitgliedschaft.sti_name)

      Group::Mitglieder::OrdentlicheMitgliedschaft.create!(
        person:, group:, start_on: "2025-12-31", fee_kind:
      )
      Group::Mitglieder::Foerdermitgliedschaft.create!(
        person:, group:, start_on: "2020-08-01", fee_kind: foerder_fee_kind
      )
      expect(person.entry_date).to eq Date.parse("2020-08-01")
    end
  end

  describe "exit_date" do
    let(:group) { groups(:adler_mitglieder) }
    let(:fee_kind) { fee_kinds(:baden_wuerttemberg_kind) }

    # the :member fixture otherwise already has an active Ordentliche
    # Mitgliedschaft (roles(:paying_member)), which would count as a
    # membership role and conflict with the ones created below
    before { roles(:paying_member).destroy }

    it "is nil without membership roles" do
      expect(person.exit_date).to be_nil
    end

    it "is nil when the membership role has no end date" do
      Group::Mitglieder::OrdentlicheMitgliedschaft.create!(
        person:, group:, start_on: "2020-01-01", fee_kind:
      )
      expect(person.exit_date).to be_nil
    end

    it "ignores non-membership roles" do
      person.roles.create!(type: person.roles.first.type, group: person.roles.first.group,
        start_on: "2020-01-01", end_on: "2020-12-31")
      expect(person.exit_date).to be_nil
    end

    it "is the end date of the most recently ended membership role" do
      foerder_fee_kind = Fabricate(:fee_kind, layer: Group.roots.first,
        role_type: Group::Mitglieder::Foerdermitgliedschaft.sti_name)

      Group::Mitglieder::OrdentlicheMitgliedschaft.create!(
        person:, group:, start_on: "2018-01-01", end_on: "2020-12-31", fee_kind:
      )
      Group::Mitglieder::Foerdermitgliedschaft.create!(
        person:, group:, start_on: "2021-01-01", end_on: "2025-08-13", fee_kind: foerder_fee_kind
      )
      expect(person.exit_date).to eq Date.parse("2025-08-13")
    end
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
