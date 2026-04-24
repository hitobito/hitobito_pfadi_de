#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module Export::Pdf::Invoice
  class RunnerWithProcessedSubjects < Runner
    private

    def sections
      return super unless group_recipient? && processed_subjects?
      super + [Export::Pdf::Invoice::ProcessedSubjectsSection]
    end

    def group_recipient? = @invoices.pluck(:recipient_type).any? { |type| type == Group.sti_name }

    def processed_subjects?
      invoice_item_ids = InvoiceItem.where(invoice_id: @invoices.pluck(:id))
      InvoiceRun::ProcessedSubject
        .where(subject_type: Person.sti_name)
        .where(item_id: invoice_item_ids)
        .exists?
    end
  end
end
