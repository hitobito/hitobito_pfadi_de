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
      thread_mattr_accessor :deferred_roles

      class << self
        def trigger(role)
          if deferred_roles
            deferred_roles << role
          else
            new(role).run
          end
        end

        # Postpones the cascade of roles restricted within the block until the
        # block has finished, so roles created later in the block count as
        # coverage. A falsy block result rolls back the whole transaction.
        def deferred(&block)
          return yield if deferred_roles

          ::Role.transaction { run_deferred(&block) }
        end

        private

        def run_deferred
          self.deferred_roles = []
          result = yield
          raise ActiveRecord::Rollback unless result

          roles = deferred_roles
          self.deferred_roles = nil
          roles.each { |role| new(role).run }
          result
        ensure
          self.deferred_roles = nil
        end
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
          .where(type: type_names(config.type))
          .where(end_on: [nil, Date.current..])
          .where.not(id: @role.id)

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

        if gap.begin == dependent.start_on
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
        dependent.destroy!
      end

      def type_names(type)
        [type, *type.descendants].map(&:sti_name)
      end
    end
  end
end
