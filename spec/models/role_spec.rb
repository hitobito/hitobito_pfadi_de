# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe Role, type: :model do
  context "fee_kinds" do
    context "for Mitglieder" do
      subject(:paying_member_role) { roles(:paying_member) }

      it "have assumptions" do
        expect(paying_member_role.class).to have_fee_kind
        expect(paying_member_role.fee_kind).to eql fee_kinds(:baden_wuerttemberg_kind)

        expect(FeeKindChooser.new(paying_member_role).possible)
          .to include(fee_kinds(:baden_wuerttemberg_kind))
      end

      it "permit the attribute fee_kind_id" do
        expect(paying_member_role.class.used_attributes)
          .to include(:fee_kind_id)
      end

      it "is invalid with missing fee_kind" do
        paying_member_role.fee_kind = nil
        expect(paying_member_role).to_not be_valid

        blank_errors = paying_member_role.errors.where(:fee_kind, :blank)
        expect(blank_errors).to have(1).item
      end

      it "sets the fee_kind if none is set" do
        new_role = Fabricate.build(
          paying_member_role.type.to_sym,
          group: paying_member_role.group
        )

        expect do
          new_role.save
        end.to change(new_role, :fee_kind)
          .from(nil).to(fee_kinds(:baden_wuerttemberg_kind))
      end

      it "is valid with a fee_kind" do
        expect(paying_member_role.fee_kind).to be_a FeeKind
        expect(paying_member_role.fee_kind).to eq fee_kinds(:baden_wuerttemberg_kind)
        expect(paying_member_role).to be_valid
      end

      it "validates that a given fee-kind is possible on save" do
        social_fee_kind = Fabricate(
          :fee_kind,
          role_type: "Group::Mitglieder::Foerdermitgliedschaft"
        )
        paying_member_role.fee_kind = social_fee_kind

        expect(paying_member_role).to_not be_valid

        inclusion_errors = paying_member_role.errors.where(:fee_kind, :inclusion)
        expect(inclusion_errors).to have(1).item
      end

      it "validates that a given fee-kind is possible on create" do
        social_fee_kind = Fabricate(
          :fee_kind,
          role_type: "Group::Mitglieder::Foerdermitgliedschaft"
        )

        new_role = Fabricate.build(
          paying_member_role.type.to_sym,
          group: paying_member_role.group,
          fee_kind: social_fee_kind
        )

        expect(new_role.save).to be_falsey

        inclusion_errors = new_role.errors.where(:fee_kind, :inclusion)
        expect(inclusion_errors).to have(1).item
      end
    end

    context "for normal roles" do
      subject(:normal_role) { roles(:member) }

      it "has assumptions" do
        expect(normal_role.class).to_not have_fee_kind
        expect(normal_role.fee_kind).to be_nil
      end

      it "does not permit the attribute fee_kind_id" do
        expect(normal_role.class.used_attributes)
          .to_not include(:fee_kind_id)
      end

      it "is valid without a fee_kind" do
        normal_role.fee_kind = nil
        expect(normal_role).to be_valid
      end

      it "does not change the after creation" do
        new_role = Fabricate.build(
          normal_role.type.to_sym,
          group: normal_role.group
        )

        expect do
          new_role.save
        end.to_not change(new_role, :fee_kind)

        expect(new_role).to be_valid
      end

      it "complains about present fee_kind" do
        normal_role.fee_kind = fee_kinds(:baden_wuerttemberg_kind)
        expect(normal_role).to_not be_valid
        expect(normal_role).to be_invalid

        errors = normal_role.errors.where(:fee_kind)
        expect(errors).to have(1).item
        expect(errors.first.type).to eql :present
      end
    end
  end
end
