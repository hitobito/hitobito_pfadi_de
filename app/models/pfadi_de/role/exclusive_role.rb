# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

module PfadiDe
  module Role
    # Registry and validation for mutually exclusive role types.
    #
    # A role type registers itself in a category, all role types of the same
    # category exclude each other within the given scope as long as their
    # validity periods (start_on..end_on) overlap:
    #
    #   class Group::Mitglieder::OrdentlicheMitgliedschaft < ::Role
    #     mutually_exclusive_roles :membership, scope: :global
    #   end
    module ExclusiveRole
      extend ActiveSupport::Concern

      SCOPES = %i[layer global].freeze
      FAR_FUTURE = Date.new(9999, 12, 31).freeze

      included do
        validate :assert_no_mutually_exclusive_roles
      end

      class_methods do
        # Declares that this role type is mutually exclusive with all other
        # role types registered in the same `category`.
        #
        # scope:         `:layer` checks for conflicts within the layer group of
        #                the role's group, `:global` checks globally irrespective of layers.
        # validate_past: with `false` (default) only the period from today on is
        #                checked, so mutations that lead to situations that would be considered
        #                inconsistent in the past stay possible. This can help to simplify
        #                correcting multiple roles in the past retroactively.
        #                `true` checks the whole validity period.
        def mutually_exclusive_roles(category, scope: :layer, validate_past: false)
          unless SCOPES.include?(scope)
            raise ArgumentError,
              "unknown scope #{scope.inspect}, expected one of #{SCOPES.inspect}"
          end

          ExclusiveRole.register(
            type: self,
            category: category.to_sym,
            scope: scope,
            validate_past: validate_past
          )
        end

        def exclusive_role_configurations
          ExclusiveRole.registry.select { |entry| entry[:type] >= self }
        end
      end

      class << self
        # Entries look like
        #   {type: SomeRoleClass, category: :membership, scope: :layer, validate_past: false}
        def registry
          @registry ||= []
        end

        def register(type:, category:, scope:, validate_past:)
          # a type occupies a single slot per category: re-registering the
          # same category replaces scope and validate_past
          registry.reject! do |entry|
            entry[:type] == type && entry[:category] == category
          end
          registry << {type: type, category: category, scope: scope, validate_past: validate_past}
        end

        # STI names of all role types registered in the category, including
        # descendants so a registration on a base class covers its subclasses.
        def type_names_in_category(category)
          registry.select { |entry| entry[:category] == category }
            .flat_map { |entry| [entry[:type], *entry[:type].descendants] }
            .map(&:sti_name)
            .uniq
        end
      end

      private

      def assert_no_mutually_exclusive_roles
        return if person.nil? || group.nil?

        self.class.exclusive_role_configurations.each do |config|
          period = exclusive_check_period(config[:validate_past])
          next if period.nil?

          conflicting_exclusive_roles(config, period).each do |conflict|
            add_exclusive_role_error(conflict)
          end
        end
      end

      def add_exclusive_role_error(conflict)
        errors.add(:base, :already_has_exclusive_role,
          role: conflict.class.model_name.human,
          group: conflict.group.decorate.name_with_layer,
          period: exclusive_role_period(conflict))
      end

      def exclusive_role_period(conflict)
        [conflict.start_on, conflict.end_on]
          .map { |date| date ? I18n.l(date) : I18n.t("role.open_end") }
          .join(" – ")
      end

      # The validity period of the role, shortened to start at today when the
      # past is not validated. Returns nil if nothing is left to check.
      def exclusive_check_period(validate_past)
        start_on = self.start_on || Date.current
        start_on = [start_on, Date.current].max unless validate_past
        end_on = self.end_on || FAR_FUTURE

        start_on..end_on if end_on >= start_on
      end

      def conflicting_exclusive_roles(config, period)
        conflicts = person.roles.with_inactive
          .active_scope(period)
          .where(type: ExclusiveRole.type_names_in_category(config[:category]))
          .where.not(id: id)

        if config[:scope] == :layer
          conflicts = conflicts
            .joins(:group)
            .where(groups: {layer_group_id: group.layer_group_id})
        end

        conflicts
      end
    end
  end
end
