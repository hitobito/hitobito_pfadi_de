#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::PeriodInvoiceTemplatesController
  extend ActiveSupport::Concern

  prepended do
    helper_method :billing_periods
    before_save :set_start_and_end_on
  end

  def set_start_and_end_on
    period = billing_periods.find(model_params[:billing_period])
    entry.start_on = period.begin
    entry.end_on = period.end
  end

  def billing_periods
    @billing_periods ||= PeriodInvoiceTemplates::BillingPeriods.new(entry.start_on, entry.end_on)
  end
end
