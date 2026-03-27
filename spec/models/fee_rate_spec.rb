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

  it "can be scoped to FeeRates which are valid today" do
    expect(described_class.valid_today.map(&:name)).to match_array [
      fee_rates(:halbjahresbeitragssatz),
      fee_rates(:kleinkinderbeitragssatz),
      fee_rates(:jahresbeitragssatz)
    ].map(&:name)
  end

  describe ".active" do
    let(:fee_kind) { fee_kinds(:baden_wuerttemberg_kind) }
    let(:reference_date) { Date.new(2025, 6, 1) }

    def create_rate(attrs)
      Fabricate(:fee_rate, fee_kind:, **attrs)
    end

    it "includes FeeRate with valid_from on reference_date and no valid_until" do
      rate = create_rate(valid_from: reference_date)
      expect(described_class.active(reference_date)).to include(rate)
    end

    it "includes FeeRate with valid_from before reference_date and no valid_until" do
      rate = create_rate(valid_from: reference_date - 1.year)
      expect(described_class.active(reference_date)).to include(rate)
    end

    it "includes FeeRate when reference_date is within valid_from and valid_until" do
      rate = create_rate(valid_from: reference_date - 1.month,
        valid_until: reference_date + 1.month)
      expect(described_class.active(reference_date)).to include(rate)
    end

    it "excludes FeeRate with valid_from after reference_date" do
      rate = create_rate(valid_from: reference_date + 1.day)
      expect(described_class.active(reference_date)).not_to include(rate)
    end

    it "excludes FeeRate with valid_until before reference_date" do
      rate = create_rate(valid_from: reference_date - 1.year, valid_until: reference_date - 1.day)
      expect(described_class.active(reference_date)).not_to include(rate)
    end

    it "includes FeeRate with valid_until exactly on reference_date" do
      rate = create_rate(valid_from: reference_date - 1.year, valid_until: reference_date)
      expect(described_class.active(reference_date)).to include(rate)
    end

    it "defaults to Date.current when no reference_date given" do
      rate = create_rate(valid_from: Date.current, valid_until: Date.current)
      expect(described_class.active).to include(rate)
    end
  end
end
