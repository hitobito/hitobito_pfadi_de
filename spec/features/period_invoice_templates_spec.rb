# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe :period_invoice_templates, js: true do
  subject { page }

  let(:user) {
    Fabricate(Group::Bundesvorstand::Bundesschatzmeister.name,
      group: groups(:bundesvorstand)).person
  }
  let(:group) { groups(:root) }

  before do
    travel_to(Time.zone.local(2026, 4, 27))
    sign_in(user)
  end

  context "create" do
    let(:new_path) { new_group_period_invoice_template_path(group) }

    it "allows to create a period invoice template with fee calculation item" do
      visit new_path
      expect(page).not_to have_text "Beitragsabrechnung"

      fill_in "Bezeichnung", with: "Mitgliedsrechnung"
      select "01.07.2025 - 31.12.2025", from: "Abrechnungsperiode"

      click_link "Rechnungsposten hinzufügen"
      click_link "Beitragsabrechnung"
      expect(page).to have_text "Entfernen", count: 1

      click_button "Speichern"

      binding.pry
      expect(page).to have_text "Sammelrechnung Mitgliedsrechnung wurde erfolgreich erstellt"
      entry = group.period_invoice_templates.first
      expect(entry).not_to be_nil
      expect(entry.recipient_source.group_type).to eq "Group::Bundesebene"
      expect(entry.items.length).to be 1
      expect(entry.items[0]).to be_instance_of PeriodInvoiceTemplate::FeeCalculationItem
    end

    it "allows to create a period invoice template with person recipients" do
      visit new_group_period_invoice_template_path(group, recipient_source_type: "PeopleFilter")
      expect(page).not_to have_text "Beitragsabrechnung"
      expect(page).to have_text group.name

      fill_in "Bezeichnung", with: "Mitgliedsrechnung"
      select "01.01.2026 - 30.06.2026", from: "Abrechnungsperiode"

      click_link "Rechnungsposten hinzufügen"
      click_link "Beitragsabrechnung"
      expect(page).to have_text "Entfernen", count: 1

      click_button "Speichern"

      expect(page).to have_text "Sammelrechnung Mitgliedsrechnung wurde erfolgreich erstellt"
      expect(page).to have_text "Personen in #{group.name}"
      entry = group.period_invoice_templates.first
      expect(entry).not_to be_nil
      expect(entry.recipient_source_type).to eq "PeopleFilter"
      expect(entry.recipient_source.group_id).to eq group.id
      expect(entry.recipient_source.range).to eq "deep"
      expect(entry.recipient_source.visible).to be_falsey
    end
  end

  context "update" do
    let(:period_invoice_template) { Fabricate(:pfadi_de_period_invoice_template) }
    let(:edit_path) { edit_group_period_invoice_template_path(group, period_invoice_template) }

    before do
      period_invoice_template.recipient_source.update!(group_type: Group::Stamm.name)
      period_invoice_template.items.delete_all
      period_invoice_template.items.create!(type: PeriodInvoiceTemplate::FeeCalculationItem,
        name: "foobar", dynamic_cost_parameters: {unit_cost: 0})
    end

    it "allows to update a period invoice template" do
      visit edit_path
      expect(page).to have_text "Beitragsabrechnung"

      fill_in "Bezeichnung", with: "Mitgliedsrechnung - edited"

      fill_in "Kostenstelle", with: "33033"
      fill_in "Konto", with: "10010"

      click_button "Speichern"

      expect(page).to have_text(
        "Sammelrechnung Mitgliedsrechnung - edited wurde erfolgreich aktualisiert"
      )
      entry = group.period_invoice_templates.first
      expect(entry).not_to be_nil
      expect(entry.recipient_source.group_type).to eq "Group::Stamm"
      expect(entry.items.length).to be 1
      expect(entry.items[0]).to be_instance_of PeriodInvoiceTemplate::FeeCalculationItem
      expect(entry.items[0].cost_center).to eq("33033")
      expect(entry.items[0].account).to eq("10010")
    end
  end
end
