#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  class FeeKind < Sheet::Invoice
    tab "fee_kinds.tabs.info",
      :group_fee_kind_path,
      if: ->(_, _, entry) { entry.present? }

    tab "fee_kinds.tabs.fee_rates",
      :group_fee_kind_fee_rates_path,
      if: ->(_, _, entry) { entry.present? }

    def title
      entry&.to_s || ::FeeKind.model_name.human(count: 2)
    end
  end
end
