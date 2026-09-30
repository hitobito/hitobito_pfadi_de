# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe Export::Tabular::Groups::Row do
  let(:stamm) { groups(:adler) }
  let(:mitglieder) { groups(:adler_mitglieder) }

  def member_count_for(group)
    described_class.new(group).member_count
  end

  it "counts the Mitglieder subgroup's people, unaffected by the Stamm's own functionaries" do
    before_count = member_count_for(stamm)
    Fabricate(Group::Stamm::Stammesfuehrung.sti_name, group: stamm)

    expect(member_count_for(stamm)).to eq(before_count)

    Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.sti_name, group: mitglieder)

    expect(member_count_for(stamm)).to eq(before_count + 1)
  end

  it "still counts the Mitglieder group's own people directly" do
    expect { Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.sti_name, group: mitglieder) }
      .to change { member_count_for(mitglieder) }.by(1)
  end

  it "falls back to the group's own people when it has no Mitglieder subgroup" do
    bundesvorstand = groups(:bundesvorstand)

    expect { Fabricate(Group::Bundesvorstand::Bundesvorsitz.sti_name, group: bundesvorstand) }
      .to change { member_count_for(bundesvorstand) }.by(1)
  end

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
