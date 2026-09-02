# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

module PfadiDe
  # Calculates the entry and exit dates of a person's primary
  # membership (currently described by has_fee_kind roles).
  #
  # Fee-relevant roles are traversed in reverse chronological order. As soon as
  # a gap of more than MAX_GAP_DAYS is found between two roles, the continuity
  # is considered broken. The start date of the most recent continuous phase is
  # returned.
  class LatestMembershipCalculator
    # Maximum gap in days between two fee-relevant roles that still counts
    # as a continuous membership.
    MAX_GAP_DAYS = 365

    def initialize(person)
      @person = person
    end

    # Returns the start date of the most recent continuous fee-relevant period,
    # or nil if no fee-relevant roles exist.
    #
    # Walks roles from newest effective end to oldest, tracking the earliest
    # covered start date. Stops at the first gap exceeding MAX_GAP_DAYS.
    # Roles without end_on are treated as still active (effective end = today).
    def entry_date
      roles_by_end = fee_relevant_roles.sort_by { |role| effective_end(role) }.reverse
      coverage_start = roles_by_end.first&.start_on

      roles_by_end.drop(1).each do |role|
        break if gap_too_large?(coverage_start, role)

        coverage_start = [coverage_start, role.start_on].min
      end

      coverage_start
    end

    # Returns the end date of the person's fee-relevant membership, or nil if
    # a fee-relevant role is still active without an end date.
    def exit_date
      return nil if membership_roles.active.where(end_on: nil).exists?

      membership_roles.maximum(:end_on)
    end

    # All fee-relevant (has_fee_kind) roles of the person, including inactive ones.
    def membership_roles
      @person.roles.with_inactive.where(type: ::Role.types_with_fee_kind.collect(&:sti_name))
    end

    private

    # Fee-relevant roles used for the entry date calculation.
    # Excludes roles without start_on and roles with a future start date.
    def fee_relevant_roles
      @fee_relevant_roles ||= membership_roles.where(start_on: ..Date.current)
    end

    def effective_end(role)
      role.end_on || Date.current
    end

    def gap_too_large?(coverage_start, role)
      (coverage_start - effective_end(role)).to_i > MAX_GAP_DAYS
    end
  end
end
