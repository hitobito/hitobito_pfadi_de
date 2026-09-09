# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe Qualification do
  describe "#set_finish_at" do
    def build_qualification(validity, start_at)
      kind = Fabricate(:qualification_kind, validity: validity)
      Qualification.new(qualification_kind: kind, start_at: start_at)
    end

    it "sets finish_at to the day before the anniversary date" do
      quali = build_qualification(2, Date.new(2026, 4, 12))
      quali.valid?

      expect(quali.finish_at).to eq(Date.new(2028, 4, 11))
    end

    it "sets finish_at to start_at if validity is 0" do
      quali = build_qualification(0, Date.new(2026, 4, 12))
      quali.valid?

      expect(quali.finish_at).to eq(Date.new(2026, 4, 12))
    end

    it "does not set finish_at if validity is nil" do
      quali = build_qualification(nil, Date.new(2026, 4, 12))
      quali.valid?

      expect(quali.finish_at).to be_nil
    end

    it "does not set finish_at if start_at is nil" do
      quali = build_qualification(2, nil)
      quali.valid?

      expect(quali.finish_at).to be_nil
    end
  end
end
