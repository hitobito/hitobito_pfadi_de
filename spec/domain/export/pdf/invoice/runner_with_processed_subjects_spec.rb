#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe Export::Pdf::Invoice::RunnerWithProcessedSubjects do
  include PdfHelpers

  let(:person) { people(:stammesverwaltung) }
  let(:group) { groups(:root) }
  let(:invoice) { Fabricate(:invoice, group:) }
  let(:pdf) { Export::Pdf::Invoice.render(invoice, articles: true) }

  it "is configured as invoice runner" do
    expect(Export::Pdf::Invoice.runner).to eq described_class
  end

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
        name: "Jahresrechnung",
        cost: 3,
        count: 10,
        dynamic_cost_parameters: {
          template_item_id: 1337,
          role_types: %w[a b c],
          unit_cost: 10.50,
          period_start_on: 1.month.ago,
          period_end_on: 1.month.from_now
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

    def expect_table_row(at:, values: [])
      positions = [57, 153, 346, 490]
      values.zip(positions).each do |value, position|
        expect(text_with_position).to include [position, at, value]
      end
    end

    it "does include Einzelnachweise header" do
      expect(text_with_position).to include [57, 770, "Einzelnachweise"]
    end

    it "includes processed subject table with single entry" do
      expect_table_row(at: 742, values: %w[ID Name Beitrag Betrag])
      expect_table_row(at: 724, values: ["332199755", "A Leader", "Jahresrechnung", "10.50 CHF"])
      expect_table_row(at: 707, values: ["820312697", "My Member", "Jahresrechnung", "10.50 CHF"])
    end

    context "multiple invoice items" do
      before do
        item = create_invoice_item(invoice_item_attrs.deep_merge(
          name: "Basisbeitrag",
          dynamic_cost_parameters: {template_item_id: 1338, unit_cost: 11.50}
        ))
        create_processed_subject(item, people(:member))
        create_processed_subject(item, people(:bottom_leader))
      end

      it "includes processed subject table with single entry" do
        expect_table_row(at: 742, values: %w[ID Name Beitrag Betrag])
        expect_table_row(at: 724, values: ["332199755", "A Leader", "Jahresrechnung", "10.50 CHF"])
        expect_table_row(at: 707, values: ["820312697", "My Member", "Jahresrechnung", "10.50 CHF"])
        expect_table_row(at: 689, values: ["332199755", "A Leader", "Basisbeitrag", "11.50 CHF"])
        expect_table_row(at: 671, values: ["820312697", "My Member", "Basisbeitrag", "11.50 CHF"])
      end
    end
  end
end
