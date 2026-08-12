#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe Export::Pdf::Invoice::RunnerWithProcessedSubjects do
  include PdfHelpers

  let(:person) { people(:stammesverwaltung) }
  let(:group) { groups(:root) }
  let(:invoice) { Fabricate(:invoice, group:, recipient_type: Group.sti_name) }
  let(:pdf) { Export::Pdf::Invoice.render(invoice, articles: true) }

  context "without processed subjects" do
    it "does not include Einzelnachweise" do
      expect(text_with_position.flatten).not_to include "Einzelnachweise"
    end
  end

  context "with processed subjects" do
    let(:member) { people(:member) }
    let(:invoice_item_attrs) do
      {
        type: Invoice::RoleCountItem.sti_name,
        name: "Erstes Halbjahr",
        cost: 3,
        count: 10,
        dynamic_cost_parameters: {
          template_item_id: 1337,
          role_types: %w[a b c],
          unit_cost: 10.50,
          period_start_on: Date.new(2026, 1, 1),
          period_end_on: Date.new(2026, 6, 1)
        }
      }
    end

    def create_invoice_item(attrs)
      invoice.invoice_items.create!(attrs)
    end

    def create_processed_subject(item, person)
      InvoiceRun::ProcessedSubject.create!(
        subject_id: person.id,
        subject_type: Person.sti_name,
        item_id: item.id,
        template_item_id: item.template_item_id
      )
    end

    before do
      item = create_invoice_item(invoice_item_attrs)
      create_processed_subject(item, people(:member))
      create_processed_subject(item, people(:bottom_leader))
    end

    def expect_table_rows(at:, row_offset: 15, values: [])
      positions = [57, 153, 346, 490]
      values.each_with_index do |row_values, index|
        row_values.zip(positions).each do |value, position|
          row_at = at - (row_offset * index)
          expect(text_with_position).to include [position, row_at, value]
        end
      end
    end

    it "does not Einzelnachweise header if invoice is not for a group" do
      invoice.update(recipient_type: Person.sti_name)
      expect(text_with_position).not_to include [57, 770, "Einzelnachweise"]
    end

    it "does include Einzelnachweise header" do
      expect(text_with_position).to include [57, 770, "Einzelnachweise"]
    end

    it "renders single header and sorted subject infos table" do
      expect(text_with_position).to include [57, 745, "Abrechnungsperiode: 01.01.2026 - 01.06.2026"]

      expect_table_rows(
        at: 726,
        values: [
          %w[Mitgliedsnr. Name Beitrag Betrag],
          ["332199755", "A Leader", "Erstes Halbjahr", "10.50 CHF"],
          ["820312697", "My Member", "Erstes Halbjahr", "10.50 CHF"]
        ]
      )
    end

    context "batch with an invoice the section does not apply to" do
      let(:non_qualifying_invoice) { Fabricate(:invoice, group:, recipient_type: Person.sti_name) }
      let(:pdf) do
        Export::Pdf::Invoice.render(
          Invoice.where(id: [invoice.id, non_qualifying_invoice.id]), articles: true
        )
      end

      it "renders Einzelnachweise once, for the invoice it applies to, not for the whole batch" do
        occurrences = text_with_position.count { |(_x, _y, text)| text == "Einzelnachweise" }
        expect(occurrences).to eq(1)
      end
    end

    context "multiple invoice items" do
      before do
        item = create_invoice_item(invoice_item_attrs.deep_merge(
          name: "Zweites Halbjahr",
          dynamic_cost_parameters: {template_item_id: 1338, unit_cost: 11.50}
        ))
        create_processed_subject(item, people(:member))
        create_processed_subject(item, people(:bottom_leader))
      end

      it "renders single header and sorted subject infos table" do
        expect(text_with_position).to include [57, 745,
          "Abrechnungsperiode: 01.01.2026 - 01.06.2026"]

        expect_table_rows(
          at: 726,
          values: [
            %w[Mitgliedsnr. Name Beitrag Betrag],
            ["332199755", "A Leader", "Erstes Halbjahr", "10.50 CHF"],
            ["332199755", "A Leader", "Zweites Halbjahr", "11.50 CHF"],
            ["820312697", "My Member", "Erstes Halbjahr", "10.50 CHF"],
            ["820312697", "My Member", "Zweites Halbjahr", "11.50 CHF"]
          ]
        )
      end
    end
  end
end
