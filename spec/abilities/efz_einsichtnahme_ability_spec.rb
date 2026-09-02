# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe EfzEinsichtnahmeAbility do
  let(:member) { people(:member) }
  let(:group) { groups(:pfadfinder) }
  let(:efz) { EfzEinsichtnahme.new(person: member) }

  def ability_for(role, group_key)
    group = groups(group_key)
    role = Fabricate.build([group.type, role].join("::"), group:)
    Ability.new(Fabricate.build(:person, roles: [role]))
  end

  describe "#show" do
    it "may not show her own" do
      expect(Ability.new(member)).not_to be_able_to(:show, efz)
    end

    it "cannot read without group read" do
      expect(ability_for("Mitglied", :pfadfinder)).not_to be_able_to(:show, efz)
    end

    it "group read can show efz" do
      expect(ability_for("Leitung", :pfadfinder)).to be_able_to(:show, efz)
    end

    it "group read from other group annot can show efz" do
      expect(ability_for("Leitung", :mondphoenixe)).not_to be_able_to(:show, efz)
    end

    it "layer_and_below_full can show efz" do
      expect(ability_for("Landesmitgliederverwaltung", :baden_wuerttemberg)).to be_able_to(:show, efz)
    end
  end

  describe "#create" do
    it "may not create her own" do
      expect(Ability.new(member)).not_to be_able_to(:create, efz)
    end

    it "Stamm::ErfassungFuehrungszeugnis may create" do
      expect(ability_for("ErfassungFuehrungszeugnis", :adler)).to be_able_to(:create, efz)
    end

    it "Stamm::ErfassungFuehrungszeugnis may not create for person in other stamm" do
      expect(ability_for("ErfassungFuehrungszeugnis", :silberreiher)).not_to be_able_to(:create, efz)
    end

    it "Landesverband::ErfassungFuehrungszeugnis may in group" do
      efz.person = Fabricate(
        Group::Landesverband::Landesmitarbeiter.sti_name,
        group: groups(:baden_wuerttemberg)
      ).person
      expect(ability_for("ErfassungFuehrungszeugnis", :baden_wuerttemberg)).to be_able_to(:create, efz)
    end

    it "Landesverband::ErfassungFuehrungszeugnis may in subgroups" do
      efz.person = Fabricate(
        Group::Mitglieder::OrdentlicheMitgliedschaft.sti_name,
        group: groups(:mitglieder_bw)
      ).person
      expect(ability_for("ErfassungFuehrungszeugnis", :baden_wuerttemberg)).to be_able_to(:create, efz)
    end

    it "Landesverband::ErfassungFuehrungszeugnis may create in layer below" do
      expect(ability_for("ErfassungFuehrungszeugnis", :baden_wuerttemberg)).to be_able_to(:create, efz)
    end
  end

  describe "#destroy" do
    let(:user) { people(:admin) }

    subject(:ability) { Ability.new(user) }

    it "may not destroy her own" do
      expect(Ability.new(member)).not_to be_able_to(:destroy, efz)
    end

    it "may destroy if role has delete_efz permission" do
      expect(ability).to be_able_to(:destroy, efz)
    end

    it "may not destroy if delete_efz permission is missing" do
      permissions = Group::Bundesebene::MVAdmin.method(:permissions)
      allow(Group::Bundesebene::MVAdmin).to receive(:permissions).and_return(permissions.call - [:delete_efz])
      expect(ability).not_to be_able_to(:destroy, efz)
    end
  end
end
