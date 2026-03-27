# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

module PfadiDe
  # Calculates the start date of a person's current uninterrupted period of
  # fee-relevant membership (last_entry_date_with_fee_kind).
  #
  # Fee-relevant roles are traversed in reverse chronological order. As soon as
  # a gap of more than MAX_GAP_DAYS is found between two roles, the continuity
  # is considered broken. The start date of the most recent continuous phase is
  # returned.
  class LastEntryDateCalculator
    # Maximum gap in days between two fee-relevant roles that still counts
    # as a continuous membership.
    MAX_GAP_DAYS = 365

    def initialize(person)
      @person = person
    end

    # Returns the start date of the most recent continuous fee-relevant period,
    # or nil if no fee-relevant roles exist.
    def calculate
      find_last_continuous_entry_date
    end

    private

    # All fee-relevant roles of the person.
    # Excludes roles without start_on and roles with a future start date.
    def fee_relevant_roles
      @fee_relevant_roles ||= @person.roles.with_inactive
        .where(type: ::Role.types_with_fee_kind.collect(&:sti_name))
        .where(start_on: ..Date.current)
    end

    # Walks roles from newest effective end to oldest, tracking the earliest
    # covered start date. Stops at the first gap exceeding MAX_GAP_DAYS.
    # Roles without end_on are treated as still active (effective end = today).
    def find_last_continuous_entry_date
      roles_by_end = fee_relevant_roles.sort_by { |role| effective_end(role) }.reverse
      coverage_start = roles_by_end.first&.start_on

      roles_by_end.drop(1).each do |role|
        break if gap_too_large?(coverage_start, role)

        coverage_start = [coverage_start, role.start_on].min
      end

      coverage_start
    end

    def effective_end(role)
      role.end_on || Date.current
    end

    def gap_too_large?(coverage_start, role)
      (coverage_start - effective_end(role)).to_i > MAX_GAP_DAYS
    end
  end
end
