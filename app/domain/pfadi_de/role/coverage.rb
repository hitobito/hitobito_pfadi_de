# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

module PfadiDe
  module Role
    # Merged union of validity periods, used to check whether a dependent role
    # is fully covered by prerequisite roles. Periods without begin or end are open.
    class Coverage
      # Period of the role that must be covered, nil if nothing is left to check.
      def self.check_period(role, validate_past)
        start_on = validate_past ? role.start_on : [role.start_on, Date.current].compact.max
        end_on = role.end_on
        start_on..end_on unless start_on && end_on && end_on < start_on
      end

      def initialize(periods)
        @sections = merge(periods)
      end

      # First sub-range of `period` that is not covered, nil if fully covered.
      def uncovered_interval(period)
        cursor = period.begin
        @sections.each do |section|
          next if ends_before?(section, cursor)
          if starts_after?(section, cursor)
            return cursor..earlier_end(section.begin - 1, period.end)
          end
          return nil if section.end.nil?

          cursor = section.end + 1
          return nil if ends_before?(period, cursor)
        end

        cursor..period.end
      end

      private

      # Sorted list of non-overlapping periods. Directly consecutive periods
      # (one ends the day before the next begins) merge into one section.
      def merge(periods)
        open_start, bounded = periods.partition { |period| period.begin.nil? }
        (open_start + bounded.sort_by(&:begin)).each_with_object([]) do |period, sections|
          last = sections.last
          if last && connected?(last, period)
            sections[-1] = last.begin..later_end(last.end, period.end)
          else
            sections << period
          end
        end
      end

      def connected?(last, period)
        last.end.nil? || period.begin.nil? || period.begin <= last.end + 1
      end

      def ends_before?(range, date)
        range.end && date && range.end < date
      end

      def starts_after?(range, date)
        range.begin && (date.nil? || range.begin > date)
      end

      def earlier_end(end_on, other_end_on)
        [end_on, other_end_on].compact.min
      end

      def later_end(end_on, other_end_on)
        end_on && other_end_on && [end_on, other_end_on].max
      end
    end
  end
end
