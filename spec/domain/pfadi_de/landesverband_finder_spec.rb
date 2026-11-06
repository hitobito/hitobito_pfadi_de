# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe PfadiDe::LandesverbandFinder do
  let(:baden_wuerttemberg) { groups(:baden_wuerttemberg) }
  let(:root) { groups(:root) }

  it "returns the group itself if it is a Landesverband" do
    expect(described_class.call(baden_wuerttemberg)).to eq(baden_wuerttemberg.id)
  end

  it "returns the nearest Landesverband ancestor" do
    bezirk = Fabricate(:"Group::Bezirk", parent: baden_wuerttemberg)
    stamm = Fabricate(:"Group::Stamm", parent: bezirk)

    expect(described_class.call(stamm)).to eq(baden_wuerttemberg.id)
  end

  it "returns nil if no Landesverband is above" do
    expect(described_class.call(root)).to be_nil
  end

  it "returns nil for nil" do
    expect(described_class.call(nil)).to be_nil
  end
end
