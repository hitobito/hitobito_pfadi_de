# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

module PfadiDe
  class RecalculateLastEntryDatesJob < RecurringJob
    run_every 1.day

    def next_run = Time.current.tomorrow.change(hour: 2, min: 0)

    private

    def perform_internal
      ::Person.where(should_recalculate_last_entry_date_with_fee_kind: true)
        .find_each do |person|
        recalculate_for_person(person)
      end
    end

    def recalculate_for_person(person)
      new_date = PfadiDe::LastEntryDateCalculator.new(person).calculate
      person.update_columns(
        last_entry_date_with_fee_kind: new_date,
        should_recalculate_last_entry_date_with_fee_kind: false
      )
    end
  end
end
