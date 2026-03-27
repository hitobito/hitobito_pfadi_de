# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe PfadiDe::LastEntryDateCalculator do
  let(:person) { Fabricate(:person) }
  let(:group) { groups(:adler_mitglieder) }

  def create_fee_role(start_on:, end_on: nil)
    role_class = Group::Mitglieder::OrdentlicheMitgliedschaft
    fee_kind = fee_kinds(:baden_wuerttemberg_kind)
    role_class.create!(person:, group:, start_on:, end_on:, fee_kind:)
  end

  describe "#calculate" do
    it "without roles returns nil" do
      expect(described_class.new(person).calculate).to be_nil
    end

    it "with only non-fee-relevant roles returns nil" do
      Group::Mitglieder::Zweitmitgliedschaft.create!(
        person: person,
        group: group,
        start_on: Date.new(2020, 1, 1)
      )
      expect(described_class.new(person).calculate).to be_nil
    end

    it "with one fee-relevant role returns the start date of that role" do
      role = create_fee_role(start_on: Date.new(2020, 1, 1))
      expect(described_class.new(person).calculate).to eq(role.start_on)
    end

    it "with multiple overlapping fee-relevant roles returns the earliest start date" do
      _role_a = create_fee_role(start_on: Date.new(2020, 6, 1))
      role_b = create_fee_role(start_on: Date.new(2020, 1, 1))
      _role_c = create_fee_role(start_on: Date.new(2020, 3, 1))
      expect(described_class.new(person).calculate).to eq(role_b.start_on)
    end

    it "with a shorter nested role uses the enclosing role's end date to bridge the gap" do
      # Role A (2020-2025) encloses Role B (2021-2022).
      # Role C starts 365 days after A ends - still continuous.
      # Without sorting by end_on, B.end_on(2022) to C.start_on(2026) looks like a gap > 365 days.
      role_a = create_fee_role(start_on: Date.new(2020, 1, 1), end_on: Date.new(2025, 1, 1))
      _role_b = create_fee_role(start_on: role_a.start_on + 1.year, end_on: role_a.end_on - 1.year)
      _role_c = create_fee_role(start_on: role_a.end_on + 365)
      expect(described_class.new(person).calculate).to eq(role_a.start_on)
    end

    it "with gap less than 1 year returns the earliest start date across the gap" do
      role = create_fee_role(start_on: Date.new(2020, 1, 1), end_on: Date.new(2020, 12, 31))
      create_fee_role(start_on: role.end_on + 6.months)
      expect(described_class.new(person).calculate).to eq(role.start_on)
    end

    it "with gap exactly 365 days returns the earliest start date across the gap" do
      role = create_fee_role(start_on: Date.new(2020, 1, 1), end_on: Date.new(2020, 12, 31))
      create_fee_role(start_on: role.end_on + 365)
      expect(described_class.new(person).calculate).to eq(role.start_on)
    end

    it "with gap greater than 365 days returns the start date after the gap" do
      role = create_fee_role(start_on: Date.new(2020, 1, 1), end_on: Date.new(2020, 12, 31))
      create_fee_role(start_on: role.end_on + 366)
      expect(described_class.new(person).calculate).to eq(role.end_on + 366)
    end

    it "with role without start_on ignores that role" do
      role = create_fee_role(start_on: Date.new(2020, 1, 1))
      create_fee_role(start_on: nil)
      expect(described_class.new(person).calculate).to eq(role.start_on)
    end

    it "with role starting in the future ignores that role" do
      role = create_fee_role(start_on: Date.new(2020, 1, 1))
      create_fee_role(start_on: Date.tomorrow)
      expect(described_class.new(person).calculate).to eq(role.start_on)
    end

    it "with multiple interruptions returns only the last continuous phase" do
      # First phase
      _role_a = create_fee_role(start_on: Date.new(2018, 1, 1), end_on: Date.new(2018, 12, 31))
      # Gap > 365 days
      # Second phase
      _role_b = create_fee_role(start_on: Date.new(2020, 6, 1), end_on: Date.new(2021, 5, 31))
      # Gap > 365 days
      # Third phase (current)
      role_c = create_fee_role(start_on: Date.new(2023, 1, 1))
      expect(described_class.new(person).calculate).to eq(role_c.start_on)
    end

    it "with no active role ended less than 365 days ago returns the start date of that phase" do
      role = create_fee_role(start_on: Date.new(2020, 1, 1), end_on: 6.months.ago.to_date)
      expect(described_class.new(person).calculate).to eq(role.start_on)
    end

    it "with role without end_on treats it as still active for gap calculation" do
      role_a = create_fee_role(start_on: Date.new(2020, 1, 1))
      _role_b = create_fee_role(start_on: Date.new(2021, 1, 1))
      # No gap because first role is still active (end_on = nil)
      expect(described_class.new(person).calculate).to eq(role_a.start_on)
    end
  end
end
