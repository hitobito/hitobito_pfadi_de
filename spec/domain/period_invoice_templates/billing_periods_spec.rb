#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe PeriodInvoiceTemplates::BillingPeriods do
  let(:half_year_periods) { false }

  before do
    travel_to(Time.zone.local(2026, 4, 24))
    allow(Settings).to receive_message_chain(:membership_fees, :half_year_periods,
      enabled: half_year_periods)
  end

  describe "#list" do
    subject(:list) { described_class.new.list }

    context "whole year" do
      it "has expected list" do
        expect(list[0].begin).to eq Date.new(2023, 1, 1)
        expect(list[0].end).to eq Date.new(2023, 12, 31)
        expect(list[1].begin).to eq Date.new(2024, 1, 1)
        expect(list[1].end).to eq Date.new(2024, 12, 31)
        expect(list[2].begin).to eq Date.new(2025, 1, 1)
        expect(list[2].end).to eq Date.new(2025, 12, 31)
        expect(list[3].begin).to eq Date.new(2026, 1, 1)
        expect(list[3].end).to eq Date.new(2026, 12, 31)
        expect(list[4].begin).to eq Date.new(2027, 1, 1)
        expect(list[4].end).to eq Date.new(2027, 12, 31)
        expect(list[5].begin).to eq Date.new(2028, 1, 1)
        expect(list[5].end).to eq Date.new(2028, 12, 31)

        expect(list[1].to_s).to eq "01.01.2024 - 31.12.2024"
      end

      it "integrates values passed into list" do
        list = described_class.new(Date.new(2000, 1, 1), Date.new(2030, 1, 1)).list
        expect(list[0].begin).to eq Date.new(2000, 1, 1)
        expect(list[1].begin).to eq Date.new(2023, 1, 1)
      end
    end

    context "half year" do
      let(:half_year_periods) { true }

      it "has expected list" do
        expect(list[0].begin).to eq Date.new(2024, 7, 1)
        expect(list[0].end).to eq Date.new(2024, 12, 31)
        expect(list[1].begin).to eq Date.new(2025, 1, 1)
        expect(list[1].end).to eq Date.new(2025, 6, 30)
        expect(list[2].begin).to eq Date.new(2025, 7, 1)
        expect(list[2].end).to eq Date.new(2025, 12, 31)
        expect(list[3].begin).to eq Date.new(2026, 1, 1)
        expect(list[3].end).to eq Date.new(2026, 6, 30)
        expect(list[4].begin).to eq Date.new(2026, 7, 1)
        expect(list[4].end).to eq Date.new(2026, 12, 31)
        expect(list[5].begin).to eq Date.new(2027, 1, 1)
        expect(list[5].end).to eq Date.new(2027, 6, 30)

        expect(list[1].to_s).to eq "01.01.2025 - 30.06.2025"
      end
    end
  end

  describe "#find" do
    subject(:periods) { described_class.new }

    it "raises if lookup fails" do
      expect { periods.find("asdf") }.to raise_error(KeyError)
      expect { periods.find("2025-01-03") }.to raise_error(KeyError)

      period = periods.find("01.01.2025 - 31.12.2025")
      expect(period.begin).to eq Date.new(2025, 1, 1)
      expect(period.end).to eq Date.new(2025, 12, 31)
    end
  end

  describe PeriodInvoiceTemplates::Period do
    it "may be sorted" do
      periods = [
        described_class.new(Date.new(2024, 1, 1), Date.new(2025, 1, 1)),
        described_class.new("2022-1-1", "2023-1-1")
      ]

      expect(periods.sort.map(&:begin)).to eq [
        Date.new(2022, 1, 1),
        Date.new(2024, 1, 1)
      ]
    end
  end
end
