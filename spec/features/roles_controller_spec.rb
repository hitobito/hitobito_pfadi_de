# frozen_string_literal: true

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz, Pfadibewegung Schweiz.
#  This file is part of hitobito and licensed under the Affero General Public
#  License version 3 or later. See the COPYING file at the top-level
#  directory or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe RolesController, js: true do
  subject { page }

  let(:group) { groups(:adler_mitglieder) }

  def choose_role(role)
    expect(page).to have_css("#role_type_select #role_type")
    find("#role_type_select #role_type").click
    expect(page).to have_css("#role_type_select #role_type option", text: role)
    find("#role_type_select #role_type").find("option", text: role).click
  end

  def choose_fee_kind(fee_kind)
    expect(page).to have_css("select#role_fee_kind_id")
    find("select#role_fee_kind_id").click
    expect(page).to have_css("select#role_fee_kind_id option", text: fee_kind)
    find("select#role_fee_kind_id option", text: fee_kind).click
  end

  describe "create" do
    let(:person) { Fabricate(:person) }
    let!(:existing_role) {
      Fabricate(Group::Stamm::Stammesbeauftragt.name, person:,
        group: groups(:adler))
    }
    let(:root) { fee_kinds(:top_fee_kind) }
    let!(:other_fee_kind) {
      Fabricate(:fee_kind, parent: root, layer: groups(:baden_wuerttemberg),
        name: "Other Fee Kind")
    }
    let!(:foerder_fee_kind) {
      Fabricate(:fee_kind, layer: groups(:root), name: "Förderbeitragsart",
        role_type: "Group::Mitglieder::Foerdermitgliedschaft")
    }

    before do
      sign_in(people(:stammesverwaltung))
      visit new_group_role_path(group_id: group, "role[person_id]": person.id)
    end

    it "creates role without fee kind" do
      choose_role("Zweitmitgliedschaft")
      expect do
        first(:button, "Speichern").click
        expect(page).to have_content "Rolle Zweitmitgliedschaft für"
        expect(page).to have_content "erfolgreich erstellt"
      end.to change { person.roles.count }.by(1)
    end

    it "creates role with default fee kind" do
      choose_role("Ordentliche Mitgliedschaft")
      expect(page).to have_content "Beitragsart"
      expect do
        first(:button, "Speichern").click
        expect(page).to have_content "Rolle Ordentliche Mitgliedschaft für"
        expect(page).to have_content "erfolgreich erstellt"
      end.to change { person.roles.count }.by(1)
      expect(person.roles.last.fee_kind_id).to eq(fee_kinds(:baden_wuerttemberg_kind).id)
    end

    it "creates role with manually selected fee kind" do
      choose_role("Ordentliche Mitgliedschaft")
      expect(page).to have_content "Beitragsart"
      choose_fee_kind("Other Fee Kind")
      expect do
        first(:button, "Speichern").click
        expect(page).to have_content "Rolle Ordentliche Mitgliedschaft für"
        expect(page).to have_content "erfolgreich erstellt"
      end.to change { person.roles.count }.by(1)
      expect(person.roles.last.fee_kind_id).to eq(other_fee_kind.id)
    end

    it "updates fee kind select when type changes" do
      expect(page).not_to have_content "Beitragsart"

      choose_role("Ordentliche Mitgliedschaft")
      expect(page).to have_content "Beitragsart"
      expect(page).to have_content "BaWü Kind"
      expect(page).not_to have_content "Förderbeitragsart"

      choose_role("Fördermitgliedschaft")
      expect(page).not_to have_content "BaWü Kind"
      expect(page).to have_content "Förderbeitragsart"
    end
  end

  describe "update" do
    let(:person) { Fabricate(:person) }
    let!(:existing_role) {
      Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, person:,
        group: groups(:adler_mitglieder))
    }

    before do
      sign_in(people(:stammesverwaltung))
      visit edit_group_role_path(group_id: group, id: existing_role.id)
    end

    it "disables select for fee kind" do
      expect(page).to have_field "Beitragsart", disabled: true
    end
  end
end
