# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe Role::List do
  let(:role_list) { Role::List.new(Ability.new(user), ActionController::Parameters.new(params)) }
  let(:user) { people(:stammesverwaltung) }
  let(:group) { groups(:adler_mitglieder) }
  let(:type) { Group::Mitglieder::OrdentlicheMitgliedschaft }
  let(:start_on) { Date.new(2025, 1, 1) }
  let(:created_at) { 33.days.ago }
  let!(:role) { Fabricate(type.sti_name, group:, start_on:, created_at:) }
  let(:types) { {type.sti_name => "1"} }

  def reloaded_role = Role.with_inactive.find_by(id: role.id)

  describe "#destroy" do
    let(:params) { {group_id: group.id, ids: role.person_id.to_s, role: {types:}} }

    it "ends membership role created long ago" do
      role_list.destroy

      expect(reloaded_role.end_on).to eq Date.current.yesterday
    end

    context "with membership role starting today" do
      let(:start_on) { Date.current }

      it "does not hard destroy role created long ago" do
        expect { role_list.destroy }.to raise_error(CanCan::AccessDenied,
          "Die Mitgliedschaft von #{role.person.full_name} kann nur innerhalb von 32 Tagen " \
          "nach dem Erfassen gelöscht werden.")

        expect(reloaded_role).to be_present
      end

      it "hard destroys recently created role" do
        role.update_columns(created_at: 32.days.ago)

        role_list.destroy

        expect(reloaded_role).to be_nil
      end

      it "hard destroys role created long ago as admin" do
        role_list = Role::List.new(Ability.new(people(:admin)),
          ActionController::Parameters.new(params))

        role_list.destroy

        expect(reloaded_role).to be_nil
      end
    end
  end

  describe "#move" do
    let(:new_type) { Group::Mitglieder::Zweitmitgliedschaft }
    let(:params) do
      {group_id: group.id, ids: role.person_id.to_s,
       role: {types:, type: new_type.sti_name, group_id: group.id}}
    end

    it "does not move membership role created long ago" do
      expect { role_list.move }.to raise_error(CanCan::AccessDenied,
        "Die Mitgliedschaft von #{role.person.full_name} kann nur innerhalb von 32 Tagen " \
        "nach dem Erfassen verschoben werden.")

      expect(role.person.roles.map(&:type)).to eq [type.sti_name]
    end

    it "moves recently created membership role" do
      role.update_columns(created_at: 32.days.ago)

      role_list.move

      expect(role.person.roles.map(&:type)).to eq [new_type.sti_name]
    end

    it "moves non-membership role created long ago" do
      role = Fabricate(Group::Stamm::Stammesbeauftragt.sti_name, group: groups(:adler),
        created_at: 33.days.ago)
      params = {group_id: groups(:adler).id, ids: role.person_id.to_s,
                role: {types: {role.type => "1"}, type: Group::Stamm::Stammesbeauftragt.sti_name,
                       group_id: groups(:adler).id, label: "Moved"}}

      Role::List.new(Ability.new(user), ActionController::Parameters.new(params)).move

      expect(role.person.roles.map(&:label)).to eq ["Moved"]
    end
  end
end
