# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe Role, type: :model do
  context "validations" do
    context "for Mitglieder" do
      subject(:paying_member_role) { roles(:paying_member) }

      it "has assumptions" do
        expect(paying_member_role.class).to have_fee_kind
        expect(paying_member_role.fee_kind).to eql fee_kinds(:baden_wuerttemberg_kind)
      end

      it "complains about missing fee_kind" do
        paying_member_role.fee_kind = nil
        expect(paying_member_role).to_not be_valid

        errors = paying_member_role.errors.where(:fee_kind)
        expect(errors).to have(1).item
        expect(errors.first.type).to eql :blank
      end

      it "deems it valid with a fee_kind" do
        expect(paying_member_role.fee_kind).to be_a FeeKind
        expect(paying_member_role).to be_valid
      end
    end

    context "for normal roles" do
      subject(:normal_role) { roles(:member) }

      it "has assumptions" do
        expect(normal_role.class).to_not have_fee_kind
        expect(normal_role.fee_kind).to be_nil
      end

      it "is valid without a fee_kind" do
        normal_role.fee_kind = nil
        expect(normal_role).to be_valid
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
