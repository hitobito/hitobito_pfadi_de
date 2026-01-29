#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  class FeeKind < Sheet::Invoice
    def title
      if entry
        link_to entry.to_s, @view.group_fee_kind_path(entry.group, entry)
      else
        ::FeeKind.model_name.human(count: 2)
      end
    end
  end
end
