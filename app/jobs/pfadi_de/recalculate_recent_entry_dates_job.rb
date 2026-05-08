# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

module PfadiDe
  class RecalculateRecentEntryDatesJob < RecalculateLastEntryDatesJob
    run_every 1.day

    def next_run = Time.current.tomorrow.change(hour: 2, min: 10)

    private

    def people_scope
      ::Person.joins(:roles_unscoped)
        .where(roles: {start_on: 1.week.ago..Time.zone.today})
    end
  end
end
