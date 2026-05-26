# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PeriodInvoiceTemplates::InvoiceRunsController, js: true do
  subject { page }

  let(:user) {
    Fabricate(Group::Bundesvorstand::Bundesschatzmeister.name,
      group: groups(:bundesvorstand)).person
  }
  let(:group) { groups(:root) }
  let(:period_invoice_template) { Fabricate(:pfadi_de_period_invoice_template) }

  let(:top_foerder_kind) {
    Fabricate(:fee_kind, layer: groups(:root),
      name: "Top Förder Kind", role_type: Group::Mitglieder::Foerdermitgliedschaft.name)
  }
  let(:land_foerder_kind) {
    Fabricate(:fee_kind, layer: groups(:baden_wuerttemberg),
      name: "Land Förder Kind", parent: top_foerder_kind)
  }
  let(:foerder_kind) {
    Fabricate(:fee_kind, layer: groups(:burg_karlsruhe),
      name: "Stamm Förder Kind", parent: land_foerder_kind)
  }
  let!(:land_foerder_fee_rate) { Fabricate(:fee_rate, fee_kind: land_foerder_kind, amount: 100) }
  let!(:foerder_fee_rate) { Fabricate(:fee_rate, fee_kind: foerder_kind, amount: 220) }

  before do
    sign_in(user)
    3.times do
      # 1 person with incomplete address
      Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group: groups(:adler_mitglieder))
      # 2 people with complete addresses in the same group
      p2 = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name,
        group: groups(:adler_mitglieder)).person
      p2.update!(street: "Greatstreet", zip_code: 80000, town: "Bern")
      p3 = Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name,
        group: groups(:mitglieder_28)).person
      p3.update!(street: "Greatstreet", zip_code: 80000, town: "Bern")
    end
    groups(:adler).update!(street: "Greatstreet", zip_code: 80000, town: "Bern")
    groups(:burg_karlsruhe).update!(street: "Karlsstrasse", zip_code: 80000, town: "Karlsruhe")
    invoice_configs(:root).update!(currency: "EUR")
  end

  context "with group recipients" do
    context "create and delete" do
      let(:index_path) {
        group_period_invoice_template_invoice_runs_path(group, period_invoice_template)
      }

      it "allows to create and delete an invoice run within a period invoice template" do
        visit index_path
        click_link "Rechnungslauf fahren"

        expect(page).to have_text "Hinweis: Falls die Filterbedingungen"
        expect(page).to have_text "Mitgliedsbeitrag"
        expect(page).to have_text "Mitgliedsbeitrag 10 0.00 % 5.00 EUR 50.00 EUR"
        expect(page).to have_text "Total inkl. MwSt. 50.00 EUR"

        fill_in "Titel", with: "Testlauf"
        click_button "Speichern"

        expect(page).to have_text "Rechnung Testlauf wurde für 3 Empfänger erstellt."
        expect(page).to have_text "Adler"
        expect(page).to have_text "35.00 EUR"
        expect(page).to have_text "Burg Karlsruhe"
        expect(page).to have_text "15.00 EUR"

        expect(page).to have_text "2 Rechnungen angezeigt."
        within first("#main tbody tr") do
          click_link "Testlauf"
        end

        expect(page).not_to have_text "2 Rechnungen angezeigt."
        expect(page).to have_text "Mitgliedsbeitrag       7 0.00 % 5.00 EUR 35.00 EUR"
        page.go_back

        expect(page).to have_text "2 Rechnungen angezeigt."
        page.find("th input[type=checkbox]").check
        click_link "Stornieren"
        expect(page).to have_text "2 Rechnungen wurden storniert"

        page.find(".sheet ul.nav li", text: "Rechnungsläufe").click
        expect(page).to have_text period_invoice_template.name
        expect(page).to have_text "Weiteren Rechnungslauf fahren"

        page.find("[alt=\"Löschen\"]").click
        expect(page).to have_text "Willst du diesen Rechnungslauf wirklich löschen?"
        click_button "Löschen"

        expect(page).to have_text "Rechnungslauf Testlauf wurde erfolgreich gelöscht."
        expect(page).to have_text "Keine Einträge gefunden"
        expect(page).to have_text "Rechnungslauf fahren"
        expect(page).not_to have_text "Weiteren Rechnungslauf fahren"
      end
    end

    context "multiple sequential invoice runs" do
      let(:index_path) {
        group_period_invoice_template_invoice_runs_path(group, period_invoice_template)
      }

      it "only considers new members added since the last invoice run" do
        # First invoice run
        # Should work normally
        visit index_path
        click_link "Rechnungslauf fahren"

        expect(page).to have_text "Hinweis: Falls die Filterbedingungen"
        expect(page).to have_text "Mitgliedsbeitrag"
        expect(page).to have_text "Mitgliedsbeitrag 10 0.00 % 5.00 EUR 50.00 EUR"
        expect(page).to have_text "Total inkl. MwSt. 50.00 EUR"

        fill_in "Titel", with: "Testlauf"
        click_button "Speichern"

        expect(page).to have_text "Rechnung Testlauf wurde für 3 Empfänger erstellt."
        expect(page).to have_text "Adler"
        expect(page).to have_text "35.00 EUR"
        expect(page).to have_text "Burg Karlsruhe"
        expect(page).to have_text "15.00 EUR"

        # In the meantime, new people are added to hitobito
        2.times do
          Fabricate(Group::Mitglieder::Foerdermitgliedschaft.name, group: groups(:mitglieder_28))
        end
        Fabricate(Group::Mitglieder::OrdentlicheMitgliedschaft.name, group: groups(:mitglieder_28))

        # Follow-up invoice run
        # Should only include the one new added role and ignore the previously invoiced ones.
        # Should not create any invoice for layers which contain no invoiceable roles at all.

        visit index_path
        click_link "Rechnungslauf fahren"

        expect(page).to have_text "Hinweis: Falls die Filterbedingungen"
        expect(page).to have_text "Mitgliedsbeitrag 1 0.00 % 5.00 EUR 5.00 EUR"

        fill_in "Titel", with: "Zweiter Testlauf"
        click_button "Speichern"

        expect(page).to have_text "Rechnung Zweiter Testlauf wurde für 3 Empfänger erstellt."
        expect(page).to have_text "1 Rechnung angezeigt."
        expect(page).not_to have_text "Adler"
        expect(page).to have_text "Burg Karlsruhe"
        expect(page).to have_text "5.00 EUR"
      end
    end
  end

  context "with people recipients" do
    before do
      period_invoice_template.update(recipient_source:)
    end

    let(:recipient_source) {
      PeopleFilter.new(
        group: Group.root, filter_chain:, range: "deep", visible: false
      )
    }
    let(:filter_chain) {
      {
        role: {
          role_types: [],
          kind: "active",
          start_at: period_invoice_template.start_on.to_s,
          finish_at: period_invoice_template.end_on.to_s,
          include_archived: true
        }
      }
    }

    let(:index_path) {
      group_period_invoice_template_invoice_runs_path(group, period_invoice_template)
    }

    it "allows to create an invoice run within a period invoice template" do
      visit index_path
      click_link "Rechnungslauf fahren"

      expect(page).to have_text "Hinweis: Falls die Filterbedingungen"
      expect(page).to have_text "Mitgliedsbeitrag 10 0.00 % 5.00 EUR 50.00 EUR"

      fill_in "Titel", with: "Testlauf"
      click_button "Speichern"

      expect(page).to have_text "Rechnung Testlauf wurde für 14 Empfänger erstellt."
      expect(page).to have_text "Für 4 Empfänger konnte keine gültige Rechnung erzeugt werden."
      expect(page).to have_text "5.00 EUR"

      expect(page).to have_text "6 Rechnungen angezeigt."
      within first("#main tbody tr") do
        click_link "Testlauf"
      end

      expect(page).not_to have_text "6 Rechnungen angezeigt."
      expect(page).to have_text "Mitgliedsbeitrag       1 0.00 % 5.00 EUR 5.00 EUR"
    end
  end
end
