# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe PfadiDe::RecalculateLastEntryDatesJob do
  let(:person1) { people(:stammesverwaltung) }
  let(:person2) { people(:member) }
  let(:group) { groups(:adler_mitglieder) }

  before do
    person1.update_attribute(:should_recalculate_last_entry_date_with_fee_kind, true)
    person2.update_attribute(:should_recalculate_last_entry_date_with_fee_kind, false)
  end

  describe "#perform" do
    it "processes only people with flag set" do
      expect(PfadiDe::LastEntryDateCalculator).to receive(:new).with(person1).and_call_original
      expect(PfadiDe::LastEntryDateCalculator).not_to receive(:new).with(person2)

      described_class.new.perform
    end

    it "updates the date with the calculated value" do
      allow_any_instance_of(PfadiDe::LastEntryDateCalculator).to receive(:calculate)
        .and_return(Date.new(42, 1, 1))
      described_class.new.perform

      expect(person1.reload.last_entry_date_with_fee_kind).to eq(Date.new(42, 1, 1))
    end

    it "resets the flag after calculation" do
      described_class.new.perform

      expect(person1.reload.should_recalculate_last_entry_date_with_fee_kind).to be false
    end

    it "handles nil result from calculator" do
      person1.update_column(:last_entry_date_with_fee_kind, Date.new(42, 1, 1))
      allow_any_instance_of(PfadiDe::LastEntryDateCalculator).to receive(:calculate).and_return(nil)
      described_class.new.perform

      expect(person1.reload.last_entry_date_with_fee_kind).to be_nil
    end

    it "processes multiple people" do
      Person.update_all(should_recalculate_last_entry_date_with_fee_kind: true)
      described_class.new.perform

      expect(Person.where(should_recalculate_last_entry_date_with_fee_kind: true).count).to eq(0)
    end
  end
end
