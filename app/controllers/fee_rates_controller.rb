# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class FeeRatesController < CrudController
  self.nesting = [Group, FeeKind]

  self.permitted_attrs = [
    :name,
    :amount,
    :valid_from,
    :valid_until
  ]

  helper_method :use_fee_rate_max_age?, :use_fee_rate_max_member_months?

  delegate :use_fee_rate_max_age?, :use_fee_rate_max_member_months?, to: :layer

  private

  def permitted_attrs
    self.class.permitted_attrs
      .then { |attrs| use_fee_rate_max_age? ? attrs + [:max_age] : attrs }
      .then { |attrs| use_fee_rate_max_member_months? ? attrs + [:max_member_months] : attrs }
  end

  def list_entries
    super.includes(fee_kind: [:layer]).list
  end

  def layer
    parents.first.decorate
  end
end
