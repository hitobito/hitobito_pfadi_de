# frozen_string_literal: true

#
#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class FeeRatesController < CrudController
  self.nesting = [Group, FeeKind]

  self.permitted_attrs = [
    :name,
    :amount,
    :valid_from,
    :valid_until,
    :max_member_months,
    :max_age
  ]

  private

  def list_entries
    super.includes(fee_kind: [:layer]).list
  end
end
