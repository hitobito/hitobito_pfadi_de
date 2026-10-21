# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe SepaMandateReadables do
  let(:member) { people(:member) }
  let(:creditor) { groups(:adler) }
  let(:mandate) { SepaMandate.new(person: member, group: creditor) }

  def readables_for(role, group_key)
    group = groups(group_key)
    role = Fabricate.build([group.type, role].join("::"), group:)
    SepaMandateReadables.new(Fabricate.build(:person, roles: [role]))
  end

  it "may read own mandate without any permission" do
    expect(SepaMandateReadables.new(member)).to be_able_to(:read, mandate)
  end

  it "may not read another person's mandate without finance permission" do
    expect(readables_for("Mitglied", :pfadfinder)).not_to be_able_to(:read, mandate)
  end

  it "may not read another person's mandate with read-only permission on the creditor layer" do
    expect(readables_for("Stammesfuehrung", :adler)).not_to be_able_to(:read, mandate)
  end

  it "may read another person's mandate with finance on the creditor layer" do
    expect(readables_for("Stammesschatzmeister", :adler)).to be_able_to(:read, mandate)
  end

  it "may read another person's mandate with layer_and_below_finance above the creditor layer" do
    expect(readables_for("Landesschatzmeister", :landesvorstand_bw)).to be_able_to(:read, mandate)
  end

  it "may not read another person's mandate with finance in a different layer" do
    expect(readables_for("Stammesschatzmeister", :silberreiher)).not_to be_able_to(:read, mandate)
  end

  it "may read any mandate as root" do
    root = Fabricate.build(:person, email: Settings.root_email)
    expect(SepaMandateReadables.new(root)).to be_able_to(:read, mandate)
  end
end
