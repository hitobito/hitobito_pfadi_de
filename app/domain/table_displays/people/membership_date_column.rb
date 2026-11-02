# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module TableDisplays
  module People
    class MembershipDateColumn < ShowDetailsColumn
      SORT_COLUMNS = {
        entry_date: :last_entry_date_with_fee_kind,
        exit_date: :last_exit_date_with_fee_kind
      }.freeze

      def required_model_attrs(_attr) = []

      def sort_by(attr)
        resolve_database_column(SORT_COLUMNS.fetch(attr.to_sym))
      end
    end
  end
end
