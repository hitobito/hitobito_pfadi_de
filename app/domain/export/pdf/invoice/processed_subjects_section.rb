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
      start_new_page
      render_header
      invoice_items.each.with_index do |item, index|
        subject_data = prepare_subjects(item)
        subject_data.prepend(table_header) if index.zero?
        render_subjects_table(subject_data)
      end
    end

    def render_header
      font_size(14) do
        text t(:header)
      end
      move_down(10)
    end

    def table_header
      COLUMNS.pluck(:label).map { |label| t(label) }
    end

    def render_subjects_table(subject_data)
      column_widths = COLUMNS.pluck(:width).map { |width| bounds.width * width }
      font_size 10 do
        table(subject_data,
          header: true,
          column_widths:,
          cell_style: {borders: [:bottom],
                       border_color: "CCCCCC",
                       border_width: 0.5,
                       padding: [2, 0, 2, 0],
                       inline_format: true})
      end
    end

    def prepare_subjects(item)
      subjects = []
      Person.where(id: processed_subjects(item)).order(:id).find_each do |person|
        subjects << [
          person.id,
          person.to_s,
          item.name,
          format_currency(dynamic_cost(item))
        ]
      end
      subjects
    end

    def processed_subjects(item)
      InvoiceRun::ProcessedSubject
        .where(subject_type: Person.sti_name)
        .where(item_id: item)
        .select(:subject_id)
    end

    def dynamic_cost(item)
      item.dynamic_cost_parameters.with_indifferent_access[:unit_cost]
    end

    def t(key)
      I18n.t(key, scope: self.class.to_s.underscore)
    end

    def format_currency(amount)
      @decorated_invoice ||= invoice.decorate
      @decorated_invoice.format_currency(amount)
    end
  end
end
