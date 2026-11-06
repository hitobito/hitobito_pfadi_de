# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe Export::Tabular::Groups::Row do
  let(:stamm) { groups(:adler) }

  describe "#landesverband_id" do
    it "exports the Landesverband's name rather than its raw id" do
      row = described_class.new(stamm)

      expect(row.fetch(:landesverband_id)).to eq(groups(:baden_wuerttemberg).name)
    end

    it "is blank for a group with no landesverband_id, such as a Landesverband itself" do
      row = described_class.new(groups(:baden_wuerttemberg))

      expect(row.fetch(:landesverband_id)).to be_nil
    end
  end
end
