# frozen_string_literal: true

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz, Pfadibewegung Schweiz.
#  This file is part of hitobito and licensed under the Affero General Public
#  License version 3 or later. See the COPYING file at the top-level
#  directory or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe Role::FeeKindChangesController, js: true do
  subject { page }

  let(:group) { groups(:adler_mitglieder) }

  let(:parent) { fee_kinds(:baden_wuerttemberg_kind) }
  let!(:stamm_fee_kind1) {
    Fabricate(:fee_kind, parent:, layer: groups(:adler), name: "Adler 1")
  }
  let!(:stamm_fee_kind2) {
    Fabricate(:fee_kind, parent:, layer: groups(:adler), name: "Adler 2")
  }

  def choose_fee_kind(fee_kind)
    expect(page).to have_css("select#role_fee_kind_change_fee_kind_id")
    find("select#role_fee_kind_change_fee_kind_id").click
    expect(page).to have_css("select#role_fee_kind_change_fee_kind_id option", text: fee_kind)
    find("select#role_fee_kind_change_fee_kind_id option", text: fee_kind).click
  end

  describe "create" do
    let(:person) { Fabricate(:person, first_name: "test", last_name: "person", nickname: "") }
    let(:role) {
      Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, person:, group:,
        fee_kind: stamm_fee_kind1, start_on: Date.new(2025, 1, 1))
    }

    before do
      sign_in(people(:stammesverwaltung))
      visit new_role_fee_kind_change_path(role_id: role)
    end

    it "works" do
      choose_fee_kind("Adler 2")
      expect do
        first(:button, "Speichern").click
        expect(page).to have_content "Die Beitragsart der Rolle wurde auf Adler 2 geändert."
      end.to change { person.roles.with_inactive.count }.by(1)
        .and change { person.roles.count }.by(0)
      expect(role.reload.end_on).to eq(Time.zone.yesterday)
    end

    it "works with future date" do
      date = 1.week.from_now
      choose_fee_kind("Adler 2")
      fill_in "Ab", with: date.strftime("%d.%m.%Y")
      expect do
        first(:button, "Speichern").click
        expect(page).to have_content "Die Beitragsart der Rolle wird am " \
          "#{date.strftime("%d.%m.%Y")} auf Adler 2 geändert."
      end.to change { person.roles.with_inactive.count }.by(1)
        .and change { person.roles.count }.by(0)
      expect(role.reload.end_on).to eq((date - 1.day).to_date)
    end

    it "works if the change date is the start date of the old role" do
      choose_fee_kind("Adler 2")
      fill_in "Ab", with: role.start_on.strftime("%d.%m.%Y")
      expect do
        first(:button, "Speichern").click
        expect(page).to have_content "Die Beitragsart der Rolle wurde auf Adler 2 geändert."
      end.to change { person.roles.with_inactive.count }.by(1)
        .and change { person.roles.count }.by(0)
      expect(role.reload.end_on).to eq(Date.new(2025, 1, 1))
    end

    it "prevents change date strictly before the start date of the old role" do
      choose_fee_kind("Adler 2")
      fill_in "Ab", with: (role.start_on - 1.day).strftime("%d.%m.%Y")
      expect do
        first(:button, "Speichern").click
        expect(page).to have_content "Ab muss 01.01.2025 oder danach sein"
      end.not_to change { person.roles.with_inactive.count }
      expect(role.reload.end_on).to be_nil
    end
  end
end
