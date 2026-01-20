#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Sheet::FeeKind do
  context "list" do
    let(:sheet) { described_class.new(self, nil, nil) }

    it "uses Beitragsarten as title" do
      expect(sheet.title).to eq "Beitragsarten"
    end
  end

  context "show" do
    let(:sheet) { described_class.new(self, nil, fee_kinds(:top_fee_kind)) }

    it "uses name of fee kind as title" do
      expect(sheet.title).to eq "Top Fee Kind"
    end
  end
end
