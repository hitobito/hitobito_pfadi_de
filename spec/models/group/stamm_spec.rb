# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe Group::Stamm do
  let(:baden_wuerttemberg) { groups(:baden_wuerttemberg) }
  let(:root) { groups(:root) }

  it "sets landesverband_id when created directly below a Landesverband" do
    stamm = Fabricate(:"Group::Stamm", parent: baden_wuerttemberg)

    expect(stamm.landesverband_id).to eq(baden_wuerttemberg.id)
  end

  it "sets landesverband_id when created below a Bezirk" do
    bezirk = Fabricate(:"Group::Bezirk", parent: baden_wuerttemberg)

    stamm = Fabricate(:"Group::Stamm", parent: bezirk)

    expect(stamm.landesverband_id).to eq(baden_wuerttemberg.id)
  end

  it "updates landesverband_id when moved directly to another Landesverband" do
    other_landesverband = Fabricate(:"Group::Landesverband", parent: root)
    stamm = Fabricate(:"Group::Stamm", parent: baden_wuerttemberg)

    Group::Mover.new(stamm).perform(other_landesverband)

    expect(stamm.reload.landesverband_id).to eq(other_landesverband.id)
  end

  it "updates landesverband_id when its Bezirk is moved to another Landesverband" do
    other_landesverband = Fabricate(:"Group::Landesverband", parent: root)
    bezirk = Fabricate(:"Group::Bezirk", parent: baden_wuerttemberg)
    stamm = Fabricate(:"Group::Stamm", parent: bezirk)

    Group::Mover.new(bezirk).perform(other_landesverband)

    expect(stamm.reload.landesverband_id).to eq(other_landesverband.id)
  end
end
