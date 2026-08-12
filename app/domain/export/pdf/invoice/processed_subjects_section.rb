#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module Export::Pdf::Invoice
  class ProcessedSubjectsSection < Section
    COLUMNS = [
      {label: :id, width: 0.2},
      {label: :name, width: 0.4},
      {label: :item, width: 0.3},
      {label: :amount, width: 0.1}
    ]

    delegate :start_new_page, :move_down, to: :pdf

    def render
      return unless applicable?

      start_new_page

      render_header
      render_subjects_table
    end

    private

    def applicable?
      invoice.recipient_type == Group.sti_name && processed_subject_infos.present?
    end

    def render_header
      font_size(14) do
        text t(:header)
      end
      move_down(10)

      font_size(10) do
        text t(:invoiced_period, start_on: I18n.l(period.begin), end_on: I18n.l(period.end))
      end
      move_down(5)
    end

    def render_subjects_table
      column_widths = COLUMNS.pluck(:width).map { |width| bounds.width * width }
      font_size 8 do
        table(table_header + table_data,
          header: true,
          column_widths:,
          cell_style: {borders: [:bottom],
                       border_color: "CCCCCC",
                       border_width: 0.5,
                       padding: [2, 0, 2, 0],
                       inline_format: true})
      end
    end

    def table_header
      [COLUMNS.pluck(:label).map { |label| t(label) }]
    end

    def table_data
      people_scope.find_each.with_object([]) do |person, subjects|
        Array(processed_subject_infos[person.id]).each do |item_id|
          subjects << [
            person.id,
            person.to_s,
            invoice_item_infos[item_id].first,
            format_currency(invoice_item_infos[item_id].second)
          ]
        end
      end
    end

    def people_scope
      Person
        .only_public_data
        .order_by_name
        .where(id: processed_subject_infos.keys)
    end

    def invoice_item_infos
      @invoice_item_infos ||= invoice.invoice_items.map do |item|
        [item.id, [item.name, item.unit_cost]]
      end.to_h
    end

    def processed_subject_infos
      @processed_subject_infos ||= InvoiceRun::ProcessedSubject
        .where(subject_type: Person.sti_name, item_id: invoice.invoice_items.map(&:id))
        .pluck(:subject_id, :item_id)
        .group_by(&:shift)
        .to_h
        .transform_values(&:flatten)
    end

    def period
      @period ||= period_start_on..period_end_on
    end

    def period_start_on = invoice.invoice_items.first.period_start_on

    def period_end_on = invoice.invoice_items.first.period_end_on

    def t(key, options = {})
      I18n.t(key, **options.merge(scope: self.class.to_s.underscore))
    end

    def format_currency(amount)
      @decorated_invoice ||= invoice.decorate
      @decorated_invoice.format_currency(amount)
    end
  end
end
