# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe PfadiDe::RecalculateRecentEntryDatesJob do
  let(:person1) { people(:stammesverwaltung) }
  let(:person2) { people(:member) }
  let(:group) { groups(:adler_mitglieder) }

  before do
    person1.roles.last.update_attribute(:start_on, 2.days.ago)
    person2.roles.last.update_attribute(:start_on, 2.weeks.ago)
  end

  describe "#perform" do
    it "processes only people with recently started roles" do
      expect(PfadiDe::LatestMembershipCalculator).to receive(:new).with(person1).and_call_original
      expect(PfadiDe::LatestMembershipCalculator).not_to receive(:new).with(person2)

      described_class.new.perform
    end

    it "updates the date with the calculated value" do
      allow_any_instance_of(PfadiDe::LatestMembershipCalculator).to receive(:entry_date)
        .and_return(Date.new(42, 1, 1))
      described_class.new.perform

      expect(person1.reload.last_entry_date_with_fee_kind).to eq(Date.new(42, 1, 1))
    end

    it "resets the flag after calculation" do
      person1.update_attribute(:should_recalculate_last_entry_date_with_fee_kind, true)
      described_class.new.perform

      expect(person1.reload.should_recalculate_last_entry_date_with_fee_kind).to be false
    end

    it "handles nil result from calculator" do
      person1.update_column(:last_entry_date_with_fee_kind, Date.new(42, 1, 1))
      allow_any_instance_of(PfadiDe::LatestMembershipCalculator).to receive(:entry_date).and_return(nil)
      described_class.new.perform

      expect(person1.reload.last_entry_date_with_fee_kind).to be_nil
    end

    it "processes multiple people" do
      Person.update_all(should_recalculate_last_entry_date_with_fee_kind: true)
      Role.update_all(start_on: Time.zone.today)
      described_class.new.perform

      expect(Person.where(should_recalculate_last_entry_date_with_fee_kind: true).count).to eq(0)
    end
  end
end
