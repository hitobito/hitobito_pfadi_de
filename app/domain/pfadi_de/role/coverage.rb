# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

module PfadiDe
  module Role
    # Merged union of validity periods, used to check whether a dependent role
    # is fully covered by prerequisite roles.
    class Coverage
      def initialize(periods)
        @sections = merge(periods)
      end

      # First sub-range of `period` that is not covered, nil if fully covered.
      def uncovered_interval(period)
        cursor = period.begin
        @sections.each do |section|
          next if section.end < cursor
          if section.begin > cursor
            return cursor..[section.begin - 1, period.end].min
          end
          cursor = [cursor, section.end + 1].max
          return nil if cursor > period.end
        end

        (cursor <= period.end) ? cursor..period.end : nil
      end

      private

      # Sorted list of non-overlapping periods. Directly consecutive periods
      # (one ends the day before the next begins) merge into one section.
      def merge(periods)
        periods.sort_by(&:begin).each_with_object([]) do |period, sections|
          last = sections.last
          if last && period.begin <= last.end + 1
            sections[-1] = last.begin..[last.end, period.end].max
          else
            sections << period
          end
        end
      end
    end
  end
end
