# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe PfadiDe::Role::Coverage do
  let(:today) { Date.current }

  describe ".check_period" do
    def role(start_on:, end_on: nil) = Role.new(start_on:, end_on:)

    it "starts today when the past is not validated" do
      expect(described_class.check_period(role(start_on: today - 10), false)).to eq(today..)
    end

    it "starts today without start when the past is not validated" do
      expect(described_class.check_period(role(start_on: nil, end_on: today + 1), false))
        .to eq(today..(today + 1))
    end

    it "starts at the start of the role when the past is validated" do
      expect(described_class.check_period(role(start_on: today - 10), true)).to eq((today - 10)..)
    end

    it "is open at the start without start when the past is validated" do
      expect(described_class.check_period(role(start_on: nil, end_on: today), true)).to eq(..today)
    end

    it "is nil for a role entirely in the past when the past is not validated" do
      expect(described_class.check_period(role(start_on: today - 10, end_on: today - 1), false))
        .to be_nil
    end
  end

  describe "#uncovered_interval" do
    def uncovered(periods, period) = described_class.new(periods).uncovered_interval(period)

    it "is nil when fully covered" do
      expect(uncovered([(today - 10)..(today + 10)], today..(today + 5))).to be_nil
    end

    it "returns the gap between consecutive periods" do
      periods = [(today - 10)..today, (today + 5)..(today + 10)]

      expect(uncovered(periods, (today - 10)..(today + 10))).to eq((today + 1)..(today + 4))
    end

    it "merges directly consecutive periods" do
      periods = [(today + 1)..(today + 10), (today - 10)..today]

      expect(uncovered(periods, (today - 10)..(today + 10))).to be_nil
    end

    it "is covered by a period with open end" do
      expect(uncovered([(today - 10)..], today..)).to be_nil
    end

    it "is covered by a period with open start" do
      expect(uncovered([..today, (today + 1)..], ..(today + 10))).to be_nil
    end

    it "returns an open ended gap after the last period" do
      expect(uncovered([(today - 10)..today], (today - 10)..)).to eq((today + 1)..)
    end

    it "returns a gap with open start before the first period" do
      expect(uncovered([(today - 10)..], ..today)).to eq(..(today - 11))
    end

    it "returns the whole period without any periods" do
      expect(uncovered([], nil..nil)).to eq(nil..nil)
    end
  end
end
