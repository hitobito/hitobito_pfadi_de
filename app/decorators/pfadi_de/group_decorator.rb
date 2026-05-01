# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::GroupDecorator
  extend ActiveSupport::Concern

  def show_new_period_invoice_template_for_groups?
    (model.class.child_types - [model.class]).any? { |type| type.layer? }
  end

  def use_fee_rate_max_member_months?
    FeatureGate.disabled? "membership_fees.relative_fee_rates"
  end

  def use_fee_rate_max_age?
    (FeatureGate.disabled? "membership_fees.relative_fee_rates") || !has_sublayers?
  end
end
