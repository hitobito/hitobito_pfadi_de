# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe Role do
  let(:person) { people(:member) }
  let(:role) { roles(:paying_member) }
  let(:group) { groups(:adler_mitglieder) }
  let(:role_class) { Group::Mitglieder::OrdentlicheMitgliedschaft }

  describe "after_commit callbacks" do
    def recalculate_flag = person.reload.should_recalculate_last_entry_date_with_fee_kind

    before do
      expect(person.should_recalculate_last_entry_date_with_fee_kind).to be false
    end

    it "marks person for recalculation on create" do
      role_class.create!(person: person, group: group, start_on: Date.current,
        fee_kind: fee_kinds(:baden_wuerttemberg_kind))

      expect(recalculate_flag).to be true
    end

    it "marks person for recalculation on update" do
      role.update!(start_on: Date.yesterday)

      expect(recalculate_flag).to be true
    end

    it "marks person for recalculation on destroy" do
      role.destroy!

      expect(recalculate_flag).to be true
    end

    it "only marks person when transaction is committed" do
      ActiveRecord::Base.transaction do
        role_class.create!(person: person, group: group, start_on: Date.current,
          fee_kind: fee_kinds(:baden_wuerttemberg_kind))
        raise ActiveRecord::Rollback
      end

      expect(recalculate_flag).to be false
    end
  end

  describe "membership flags on Group::Mitglieder roles" do
    # membership_role is used by the bdp wagon (Bdp::RoleAbility,
    # Bdp::MissingMembershipRoleCreatePermission) to gate role creation
    # behind :create_membership_roles and other permission related aspects
    it "sets membership_role on all three role types" do
      expect(Group::Mitglieder::OrdentlicheMitgliedschaft.membership_role).to be true
      expect(Group::Mitglieder::Foerdermitgliedschaft.membership_role).to be true
      expect(Group::Mitglieder::Zweitmitgliedschaft.membership_role).to be true
    end

    # official_membership_role is narrower: only the bylaws-defined
    # Ordentliche/Foerdermitgliedschaft, used for Person#entry_date,
    # #exit_date and #membership_group.
    it "sets official_membership_role only on Ordentliche and Foerdermitgliedschaft" do
      expect(Group::Mitglieder::OrdentlicheMitgliedschaft.official_membership_role).to be true
      expect(Group::Mitglieder::Foerdermitgliedschaft.official_membership_role).to be true
      expect(Group::Mitglieder::Zweitmitgliedschaft.official_membership_role).to be false
    end
  end
end
