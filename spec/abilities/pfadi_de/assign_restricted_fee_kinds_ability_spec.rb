# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe RoleAbility do
  subject(:ability) { Ability.new(user.reload) }

  let(:role) { roles(:paying_member) }
  let(:new_role) do
    Group::Mitglieder::OrdentlicheMitgliedschaft.new(group: groups(:adler_mitglieder),
      person: Fabricate(:person), fee_kind: fee_kinds(:baden_wuerttemberg_kind))
  end

  before { fee_kinds(:top_fee_kind).update!(restricted: true) }

  context "with assign_restricted_fee_kinds on Bundesebene" do
    let(:user) { people(:admin) }

    it "may assign restricted fee kinds" do
      is_expected.to be_able_to(:assign_restricted_fee_kinds, role)
    end

    it "may create role with restricted fee kind" do
      is_expected.to be_able_to(:create, new_role)
    end
  end

  context "with assign_restricted_fee_kinds on Landesverband" do
    let(:user) do
      Fabricate(Group::Landesverband::Landesmitgliederverwaltung.sti_name,
        group: groups(:baden_wuerttemberg)).person
    end

    it "may assign restricted fee kinds to roles below" do
      is_expected.to be_able_to(:assign_restricted_fee_kinds, role)
    end
  end

  context "without assign_restricted_fee_kinds" do
    let(:user) { people(:stammesverwaltung) }

    it "may not assign restricted fee kinds" do
      is_expected.not_to be_able_to(:assign_restricted_fee_kinds, role)
    end

    it "may not create role with restricted fee kind" do
      is_expected.not_to be_able_to(:create, new_role)
    end

    it "may create role with unrestricted fee kind" do
      fee_kinds(:top_fee_kind).update!(restricted: false)

      is_expected.to be_able_to(:create, new_role)
    end
  end
end
