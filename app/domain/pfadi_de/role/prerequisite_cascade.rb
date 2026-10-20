# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

module PfadiDe
  module Role
    # Shrinks or deletes dependent roles after the validity period of a
    # prerequisite role has been restricted or the role has been destroyed.
    # Coverage is computed from the persisted roles only.
    #
    # The cascade runs transitively: shortening a dependent role that is itself
    # a prerequisite role triggers the cascade for its own dependents again.
    class PrerequisiteCascade
      def self.trigger(role)
        new(role).run
      end

      def initialize(role)
        @role = role
      end

      def run
        @role.class.provided_prerequisite_categories.each do |category|
          PrerequisiteRole.dependent_configurations(category).each do |config|
            affected_dependents(config).each do |dependent|
              adjust(dependent, config)
            end
          end
        end
      end

      private

      def affected_dependents(config)
        dependents = @role.person.roles.with_inactive
          .where(type: config.type.sti_name)
          .where.not(id: @role.id)
        dependents = dependents.where(end_on: [nil, Date.current..]) unless config.validate_past

        if config.scope == :layer
          dependents = dependents
            .joins(:group)
            .where(groups: {layer_group_id: @role.group.layer_group_id})
        end

        dependents
      end

      # Shortens the dependent role to the coverage of its check period. A
      # dependent role uncovered right at its start moves behind the gap.
      def adjust(dependent, config)
        period = dependent.prerequisite_check_period(config.validate_past)
        coverage = dependent.prerequisite_coverage(config)
        gap = period && coverage.uncovered_interval(period)
        return if gap.nil?

        if gap.begin == (dependent.start_on || PrerequisiteRole::FAR_PAST)
          move_behind(dependent, coverage, gap, period)
        else
          update_period(dependent, start_on: dependent.start_on, end_on: gap.begin - 1)
        end
      end

      def move_behind(dependent, coverage, gap, period)
        return remove(dependent) if gap.end == period.end

        start_on = gap.end + 1
        next_gap = coverage.uncovered_interval(start_on..period.end)
        end_on = next_gap ? next_gap.begin - 1 : dependent.end_on
        update_period(dependent, start_on:, end_on:)
      end

      def update_period(dependent, start_on:, end_on:)
        dependent.start_on = start_on
        dependent.end_on = end_on
        dependent.save!(validate: false)
      end

      def remove(dependent)
        dependent.really_destroy! ||
          raise(ActiveRecord::RecordNotDestroyed.new("Failed to destroy the record", dependent))
      end
    end
  end
end
