# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe PfadiDe::Role::Coverage do
  let(:today) { Date.current }

  describe ".period" do
    it "spans start and end" do
      expect(described_class.period(today - 10, today + 10)).to eq((today - 10)..(today + 10))
    end

    it "is open without start and end" do
      expect(described_class.period(nil, nil))
        .to eq(described_class::FAR_PAST..described_class::FAR_FUTURE)
    end
  end

  describe ".check_period" do
    def role(start_on:, end_on: nil) = Role.new(start_on:, end_on:)

    it "starts today when the past is not validated" do
      expect(described_class.check_period(role(start_on: today - 10), false))
        .to eq(today..described_class::FAR_FUTURE)
    end

    it "starts at the start of the role when the past is validated" do
      expect(described_class.check_period(role(start_on: today - 10), true))
        .to eq((today - 10)..described_class::FAR_FUTURE)
    end

    it "starts in the far past without start when the past is validated" do
      expect(described_class.check_period(role(start_on: nil, end_on: today), true))
        .to eq(described_class::FAR_PAST..today)
    end

    it "is nil for a role entirely in the past when the past is not validated" do
      expect(described_class.check_period(role(start_on: today - 10, end_on: today - 1), false))
        .to be_nil
    end
  end
end
