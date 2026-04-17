# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class PeriodInvoiceTemplate::FeeCalculationItem < PeriodInvoiceTemplate::Item
  def to_invoice_item_for_groups(invoice: nil, recipient_groups: nil, attrs: {})
    fee_rates.map do |fee_rate|
      super(invoice:, recipient_groups:, attrs: attrs.deep_merge(
        name: fee_rate.name, unit_cost: nil, dynamic_cost_parameters: {fee_rate_id: fee_rate.id}
      ))
    end
  end

  def to_invoice_item_for_people(invoice: nil, recipient_people: nil, attrs: {})
    fee_rates.map do |fee_rate|
      super(invoice:, recipient_people:, attrs: attrs.deep_merge(
        name: fee_rate.name, unit_cost: nil, dynamic_cost_parameters: {fee_rate_id: fee_rate.id}
      ))
    end
  end

  private

  def fee_rates
    @fee_rates ||= period_invoice_template.group.fee_rates.active(period_invoice_template.start_on)
  end
end
