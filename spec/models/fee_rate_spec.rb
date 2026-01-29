# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe FeeRate, type: :model do
  subject { fee_rates(:jahresbeitragssatz) }

  describe "has validations, which enforce" do
    it "valid fixtures" do
      is_expected.to be_valid
    end

    it "valid_from to be filled" do
      subject.valid_from = nil

      expect(subject).to_not be_valid
    end

    it "fee_kind_id to be present" do
      subject.fee_kind_id = nil

      expect(subject).to_not be_valid
    end
  end

  it "belongs to a FeeKind" do
    expect(subject.fee_kind).to be_a FeeKind
  end

  it "has a readable to_s" do
    expect(subject.to_s).to eq "Jahresbeitrag"
  end

  it "can be sorted by descending valid_from and valid_until" do
    expect(described_class.list.map(&:name)).to eql [
      fee_rates(:halbjahresbeitragssatz),
      fee_rates(:kleinkinderbeitragssatz),
      fee_rates(:jahresbeitragssatz),
      fee_rates(:alter_halbjahresbeitragssatz)
    ].map(&:name)
  end
end
