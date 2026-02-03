#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe FeeKind do
  context "#to_s" do
    let(:top_fee_kind) { fee_kinds(:baden_wuerttemberg_kind) }
    let(:bottom_fee_kind) { fee_kinds(:baden_wuerttemberg_kind) }

    it "returns name" do
      expect(bottom_fee_kind.to_s).to eq bottom_fee_kind.name
    end

    it "returns name and role_type of parent when format is with_role_type" do
      expect(bottom_fee_kind.to_s(:with_role_type)).to eq "#{bottom_fee_kind.name} (Rolle)"
    end

    it "returns name and role_type when format is with_role_type and fee_kind is top layer" do
      expect(top_fee_kind.to_s(:with_role_type)).to eq "#{top_fee_kind.name} (Rolle)"
    end
  end

  context "#human_role_name" do
    let(:top_fee_kind) { fee_kinds(:baden_wuerttemberg_kind) }

    it "returns translated role label" do
      expect(top_fee_kind.human_role_name).to eq "Rolle"
    end
  end

  context "top layer" do
    let(:fee_kind) { fee_kinds(:top_fee_kind) }

    it "is valid" do
      expect(fee_kind).to be_valid
    end

    it "validates presence of name" do
      fee_kind.name = nil
      expect(fee_kind).not_to be_valid
    end

    it "does not validate presence of parent" do
      fee_kind.parent = nil
      expect(fee_kind).to be_valid
    end

    it "validates absence of parent" do
      fee_kind.parent = fee_kinds(:top_fee_kind)
      expect(fee_kind).not_to be_valid
    end

    it "validates presence of role_type" do
      fee_kind.role_type = nil
      expect(fee_kind).not_to be_valid
    end

    it "validates presence of restricted" do
      fee_kind.restricted = nil
      expect(fee_kind).not_to be_valid
    end

    it "cannot change role_type after create" do
      fee_kind.update!(role_type: "new_role_type")
      fee_kind.reload
      expect(fee_kind.role_type).to eq "Group::Sippe::Pfadfinder"
    end

    it "#restricted? returns restricted value" do
      expect(fee_kind.restricted?).to be_falsy
      fee_kind.restricted = true
      expect(fee_kind.restricted?).to be_truthy
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

    it "validates absence of restricted" do
      fee_kind.restricted = false
      expect(fee_kind).not_to be_valid
    end

    it "cannot change parent_id after create" do
      fee_kind.update!(parent: FeeKind.build(name: "New Fee Kind",
        parent: fee_kinds(:top_fee_kind),
        layer: groups(:root)))
      fee_kind.reload
      expect(fee_kind.parent).to eq fee_kinds(:top_fee_kind)
    end

    it "#restricted? returns restricted value of highest parent" do
      expect(fee_kind.restricted?).to be_falsy
      fee_kind.parent.update!(restricted: true)
      expect(fee_kind.restricted?).to be_truthy
    end
  end

  context "root_fee_kind_of" do
    let(:root) { fee_kinds(:top_fee_kind) }
    let(:level_1) {
      FeeKind.create!(name: "Level 1", parent: root, layer: groups(:baden_wuerttemberg))
    }
    let(:group_level_2) { Fabricate(Group::Stamm.sti_name, parent: groups(:baden_wuerttemberg)) }
    let(:level_2) { FeeKind.create!(name: "Level 2", parent: level_1, layer: group_level_2) }

    it "returns nil if fee_kind has no parent" do
      expect(FeeKind.root_fee_kind_of(root)).to be_nil
    end

    it "returns the parent if only two levels exist" do
      result = FeeKind.root_fee_kind_of(level_1)
      expect(result).to eq(root)
    end

    it "climbs multiple levels to find the root ancestor" do
      result = FeeKind.root_fee_kind_of(level_2)

      expect(result).to eq(root)
      expect(result.parent_id).to be_nil
    end
  end

  it "validates that no parent match on create" do
    group = Fabricate(Group::Stamm.sti_name, parent: groups(:baden_wuerttemberg))
    new_fee_kind = FeeKind.build(name: "New Fee Kind", parent: fee_kinds(:top_fee_kind),
      layer: group)
    expect(new_fee_kind).not_to be_valid
    expect(new_fee_kind.errors.full_messages.first).to eq(<<~MSG.squish)
      Erbt von wurde bereits durch eine Beitragsart (#{fee_kinds(:baden_wuerttemberg_kind)})
      überschrieben welche sich in einer höheren Ebene befindet.
    MSG
    fee_kinds(:baden_wuerttemberg_kind).destroy!
    expect(new_fee_kind).to be_valid
  end

  it "allows creation of multiple fee kinds per layer with same parent" do
    expect(groups(:baden_wuerttemberg).fee_kinds.count).to eq 1
    new_fee_kind = FeeKind.build(name: "New Fee Kind", parent: fee_kinds(:top_fee_kind),
      layer: groups(:baden_wuerttemberg))
    expect(new_fee_kind).to be_valid
  end

  context "#possible_fee_kind_parents" do
    let(:group) { groups(:baden_wuerttemberg) }
    let(:parent_fee_kind) { fee_kinds(:top_fee_kind) }

    subject(:fee_kind) do
      FeeKind.create(
        name: "TheLänd-Beitrag",
        layer: group.layer_group,
        parent: parent_fee_kind
      )
    end

    it "returns fee kinds from all parent layers" do
      expect(fee_kind.possible_fee_kind_parents).to match_array [
        parent_fee_kind
      ]
    end

    it "does not include those already used in higher layers" do
      stamm = Fabricate(Group::Stamm.sti_name, parent: groups(:baden_wuerttemberg))
      stamm_fee_kind = FeeKind.build(name: "NichtHochdeutschBeitrag", layer: stamm.layer_group)

      expect(stamm_fee_kind.possible_fee_kind_parents).to_not include(parent_fee_kind)
      expect(stamm_fee_kind.possible_fee_kind_parents).to match_array [
        fee_kinds(:baden_wuerttemberg_kind),
        fee_kind
      ]
    end

    it "does not include archived fee kinds" do
      parent_fee_kind.update(archived_at: 2.days.ago.to_date)

      expect(fee_kind.possible_fee_kind_parents).to_not include(parent_fee_kind)
    end

    it "does include fee kinds archived in the future" do
      parent_fee_kind.update(archived_at: 2.days.from_now.to_date)

      expect(fee_kind.possible_fee_kind_parents).to include(parent_fee_kind)
    end
  end

  context "can have many FeeRates," do
    it "but does not need to" do
      expect(fee_kinds(:top_fee_kind)).to have(0).fee_rates
    end

    it "which belong to it" do
      expect(fee_kinds(:baden_wuerttemberg_kind)).to have(4).fee_rates
    end
  end
end
