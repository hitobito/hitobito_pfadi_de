# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe FeeRate, type: :model do
  subject { fee_rates(:jahresbeitragssatz) }

  def create_process_subject(dynamic_cost_parameters = {})
    item = InvoiceItem.create!(
      invoice_id: 1,
      name: "name",
      unit_cost: 1,
      dynamic_cost_parameters:
    )
    InvoiceRun::ProcessedSubject.create!(
      subject_id: 1,
      subject_type: "Person",
      template_item_id: 1,
      item:
    )
  end

  describe "::validations" do
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

    context "used" do
      [
        [:name, "newName"],
        [:amount, 1],
        [:valid_from, Date.yesterday],
        [:max_member_months, 5],
        [:max_age, 18]
      ].each do |attr, value|
        it "may change #{attr} if not used" do
          subject.send(:"#{attr}=", value)
          expect(subject).to be_valid
        end

        it "may not change #{attr} if used" do
          create_process_subject(fee_rate_id: subject.id)
          subject.send(:"#{attr}=", value)
          expect(subject).not_to be_valid
          expect(subject.errors.full_messages).to eq [
            "#{FeeRate.human_attribute_name(attr)} darf nicht verändert werden"
          ]
        end
      end

      it "may change valid_until even if in used" do
        create_process_subject(fee_rate_id: subject.id)
        subject.valid_until = Date.tomorrow
        expect(subject).to be_valid
      end
    end
  end

  describe "#used?" do
    it "is false if no processed subjects exists" do
      expect(subject).not_to be_used
    end

    it "is false if processed subject does not match" do
      create_process_subject(foo: :bar)
      expect(subject).not_to be_used
    end

    it "is false for processed subject matching other fee_rate" do
      create_process_subject(fee_rate_id: 2)
      expect(subject).not_to be_used
    end

    it "is true for processed subject does match" do
      create_process_subject(fee_rate_id: subject.id)
      expect(subject).to be_used
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

  describe "#total_yearly_amount" do
    let(:fee_rate) { fee_rates(:jahresbeitragssatz) }
    let(:fee_kind) { fee_kinds(:baden_wuerttemberg_kind) }
    let(:date) { Time.zone.today }

    subject { fee_rate.total_yearly_amount(date) }

    context "without relative fee rates (BdP)" do
      before do
        allow(FeatureGate).to receive(:enabled?).with("membership_fees.relative_fee_rates")
          .and_return false
      end

      it "returns the fee rate's amount" do
        is_expected.to eq 90
      end

      it "ignores parent fee rate's amount" do
        Fabricate(:fee_rate, fee_kind: fee_kind.parent, amount: 10)
        is_expected.to eq 90
      end

      it "ignores parent inactive fee rate" do
        Fabricate(:fee_rate, fee_kind: fee_kind.parent, amount: 10, valid_until: 1.year.ago)
        is_expected.to eq 90
      end
    end

    context "with relative fee rates (DPSG)" do
      before do
        allow(FeatureGate).to receive(:enabled?).with("membership_fees.relative_fee_rates")
          .and_return true
      end

      it "returns the fee rate's amount" do
        is_expected.to eq 90
      end

      it "adds parent fee rate's amount" do
        Fabricate(:fee_rate, fee_kind: fee_kind.parent, amount: 10)
        is_expected.to eq 100
      end

      it "ignores parent inactive fee rate" do
        Fabricate(:fee_rate, fee_kind: fee_kind.parent, amount: 10, valid_until: 1.year.ago)
        is_expected.to eq 90
      end
    end
  end
end
