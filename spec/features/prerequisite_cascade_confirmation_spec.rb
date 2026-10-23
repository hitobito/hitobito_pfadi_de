# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe "Prerequisite cascade confirmation", js: true do
  let(:group) { groups(:adler_mitglieder) }
  let(:person) { Fabricate(:person, first_name: "Paula", last_name: "Pfadi", nickname: "") }
  let!(:membership) do
    Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.sti_name,
      person:, group:, start_on: 1.year.ago.to_date)
  end
  let!(:dependent) do
    Fabricate(Group::StammGruppePfadfinder::Mitglied.sti_name,
      person:, group: groups(:pfadfinder), start_on: 6.months.ago.to_date)
  end

  around do |example|
    registry = PfadiDe::Role::PrerequisiteRole.registry.dup
    example.run
    PfadiDe::Role::PrerequisiteRole.registry.replace(registry)
  end

  before do
    Group::Mitglieder::OrdentlicheMitgliedschaft.provides_role :stamm_mitgliedschaft
    Group::StammGruppePfadfinder::Mitglied
      .depends_on_role :stamm_mitgliedschaft, scope: :layer, on_uncovered: :cascade
    sign_in(people(:stammesverwaltung))
  end

  def expect_confirmation_of_dependent_ending_on(end_on)
    start_on = I18n.l(dependent.start_on)
    expect(page).to have_css("h1", text: "Abhängige Rollen anpassen")
    ["Paula Pfadi", "Adler / Pfadfinder*innen", "#{start_on} – offen",
      "#{start_on} – #{I18n.l(end_on)}"].each do |text|
      expect(page).to have_css("td", text:)
    end
  end

  describe "editing a membership" do
    let(:end_on) { 1.month.from_now.to_date }

    before do
      visit edit_group_role_path(group, membership)
      fill_in "role_end_on", with: I18n.l(end_on)
      first(:button, "Speichern").click
    end

    it "shortens the dependent role after confirmation" do
      expect_confirmation_of_dependent_ending_on(end_on)
      expect(membership.reload.end_on).to be_nil

      click_button "Änderung bestätigen"

      expect(page).to have_content "erfolgreich aktualisiert"
      expect(membership.reload.end_on).to eq end_on
      expect(dependent.reload.end_on).to eq end_on
    end

    it "keeps all roles when cancelled" do
      expect(page).to have_css("h1", text: "Abhängige Rollen anpassen")

      click_link "Abbrechen"

      expect(page).to have_current_path(edit_group_role_path(group, membership))
      expect(membership.reload.end_on).to be_nil
      expect(dependent.reload.end_on).to be_nil
    end
  end

  describe "deleting a membership" do
    it "ends the dependent role after confirmation" do
      visit group_person_path(group, person)
      accept_confirm do
        find("a[data-method='delete'][href='#{group_role_path(group, membership)}']").click
      end

      expect_confirmation_of_dependent_ending_on(Date.yesterday)

      click_button "Änderung bestätigen"

      expect(page).to have_content "erfolgreich gelöscht"
      expect(person.roles.where(id: membership.id)).to be_empty
      expect(dependent.reload.end_on).to eq Date.yesterday
    end
  end

  describe "bulk role actions in the people list" do
    before do
      visit group_people_path(group)
      find("input[name='ids[]'][value='#{person.id}']").click
      expect(page).to have_content("1 ausgewählt")
      click_link("Rollen")
    end

    it "ends the dependent role after confirming the removal" do
      click_link("Rollen entfernen")
      expect(page).to have_content("Welche Rollen sollen gelöscht werden?")
      click_button("Entfernen")

      expect_confirmation_of_dependent_ending_on(Date.yesterday)

      click_button "Änderung bestätigen"

      expect(page).to have_content("Eine Rolle wurde entfernt")
      expect(person.roles.where(id: membership.id)).to be_empty
      expect(dependent.reload.end_on).to eq Date.yesterday
    end

    it "ends the dependent role after confirming the move" do
      click_link("Rollen verschieben")
      select("Zweitmitgliedschaft", from: "role_type")
      click_button("Weiter")
      click_button("Rollen verschieben")

      expect_confirmation_of_dependent_ending_on(Date.yesterday)

      click_button "Änderung bestätigen"

      expect(page).to have_content("Eine Rolle wurde verschoben")
      expect(person.roles.map(&:type)).to include(Group::Mitglieder::Zweitmitgliedschaft.sti_name)
      expect(dependent.reload.end_on).to eq Date.yesterday
    end
  end
end
