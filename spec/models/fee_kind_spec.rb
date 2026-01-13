#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe FeeKind do
  context "top layer" do
    let(:fee_kind) { fee_kinds(:top_fee_kind) }

    it "is valid" do
      expect(fee_kind).to be_valid
    end

    it "validates presence of name" do
      fee_kind.name = nil
      expect(fee_kind).not_to be_valid
    end

    it "validates presence of layer" do
      fee_kind.layer = nil
      expect(fee_kind).not_to be_valid
    end

    it "does not validate presence of parent" do
      fee_kind.parent = nil
      expect(fee_kind).to be_valid
    end

    it "validates presence of role_type" do
      fee_kind.role_type = nil
      expect(fee_kind).not_to be_valid
    end

    it "cannot change role_type after create" do
      fee_kind.update!(role_type: "new_role_type")
      fee_kind.reload
      expect(fee_kind.role_type).to eq "Group::Sippe::Pfadfinder"
    end
  end

  context "bottom layer" do
    let(:fee_kind) { fee_kinds(:baden_wuerttemberg_kind) }

    it "validates presence of parent" do
      fee_kind.parent = nil
      expect(fee_kind).not_to be_valid
    end

    it "validates absence of role_type" do
      fee_kind.role_type = roles(:member).type
      expect(fee_kind).not_to be_valid
    end
  end

  it "validates that no parent match on create" do
    group = Fabricate(Group::Stamm.sti_name, parent: groups(:baden_wuerttemberg))
    new_fee_kind = FeeKind.build(name: "New Fee Kind", parent: fee_kinds(:top_fee_kind),
      layer: group)
    expect(new_fee_kind).not_to be_valid
    expect(new_fee_kind.errors.full_messages.first).to eq "Erbt von wurde bereits durch eine " \
                                                          "Beitragsart (Bottom Fee Kind) " \
                                                          "überschrieben welche sich in einer " \
                                                          "höheren Ebene befindet."
    fee_kinds(:baden_wuerttemberg_kind).destroy!
    expect(new_fee_kind).to be_valid
  end

  it "allows creation of multiple fee kinds per layer with same parent" do
    expect(groups(:baden_wuerttemberg).fee_kinds.count).to eq 1
    new_fee_kind = FeeKind.build(name: "New Fee Kind", parent: fee_kinds(:top_fee_kind),
      layer: groups(:baden_wuerttemberg))
    expect(new_fee_kind).to be_valid
  end
end
