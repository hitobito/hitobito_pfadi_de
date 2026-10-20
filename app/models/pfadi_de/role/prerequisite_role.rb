# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

module PfadiDe
  module Role
    # Registry and validation for prerequisite roles.
    #
    # A role type declares that it provides a prerequisite category, another
    # role type declares that it depends on prerequisite roles of a category:
    #
    #   class Group::Mitglieder::OrdentlicheMitgliedschaft < ::Role
    #     provides_role :stamm_mitgliedschaft
    #   end
    #
    #   class Group::StammGruppePfadfinder::Mitglied < ::Role
    #     depends_on_role :stamm_mitgliedschaft, scope: :layer, on_uncovered: :cascade
    #   end
    #
    # A dependent role is only valid while its validity period is fully covered
    # by prerequisite roles of the person in the configured scope.
    module PrerequisiteRole
      extend ActiveSupport::Concern

      CircularDependencyError = Class.new(StandardError)

      Provider = Data.define(:type, :category)
      Dependency = Data.define(:type, :category, :scope, :validate_past, :on_uncovered)

      SCOPES = %i[layer global].freeze
      ON_UNCOVERED = %i[prevent cascade].freeze
      FAR_FUTURE = Date.new(9999, 12, 31).freeze

      included do
        validate :assert_prerequisite_coverage
      end

      class_methods do
        # Declares that instances of this role type satisfy prerequisites of the
        # `category`.
        def provides_role(category)
          PrerequisiteRole.register(Provider.new(type: self, category: category.to_sym))
        end

        # Declares that instances of this role type require coverage by
        # prerequisite roles of the `category`.
        #
        # scope:         `:layer` counts only prerequisite roles within the layer
        #                of the role's group, `:global` counts all prerequisite
        #                roles of the person.
        # validate_past: with `false` (default) only the period from today on
        #                must be covered.
        # on_uncovered:  behavior when the coverage is lost through a change to
        #                a prerequisite role. Only `:cascade` is implemented so
        #                far.
        def depends_on_role(category, scope: :layer, validate_past: false, on_uncovered: :prevent)
          PrerequisiteRole.validate_dependency_options!(
            scope: scope,
            validate_past: validate_past,
            on_uncovered: on_uncovered
          )

          PrerequisiteRole.register(
            Dependency.new(
              type: self,
              category: category.to_sym,
              scope: scope,
              validate_past: validate_past,
              on_uncovered: on_uncovered
            )
          )
        end

        def dependent_role_configurations
          PrerequisiteRole.configurations(Dependency, self)
        end

        def provided_prerequisite_categories
          PrerequisiteRole.configurations(Provider, self).map(&:category)
        end
      end

      class << self
        def registry
          @registry ||= []
        end

        def register(entry)
          registry.reject! do |existing|
            existing.instance_of?(entry.class) &&
              existing.type == entry.type &&
              existing.category == entry.category
          end
          registry << entry
          assert_acyclic!(entry.type)
        rescue CircularDependencyError
          registry.delete(entry)
          raise
        end

        # STI names of all role types providing the category, including
        # descendants so a registration on a base class covers its subclasses.
        def provider_type_names(category)
          registry.grep(Provider).select { |e| e.category == category }
            .flat_map { |e| [e.type, *e.type.descendants] }
            .map(&:sti_name)
            .uniq
        end

        # Registry entries of the given entry class whose registered type is
        # the role class or one of its ancestors.
        def configurations(entry_class, type)
          registry.grep(entry_class).select { |entry| entry.type >= type }
        end

        def dependent_configurations(category)
          registry.grep(Dependency).select { |e| e.category == category }
        end

        def validate_dependency_options!(scope:, validate_past:, on_uncovered:)
          assert_known_option!(:scope, scope, SCOPES)
          assert_known_option!(:on_uncovered, on_uncovered, ON_UNCOVERED)
          if validate_past
            raise NotImplementedError, "validate_past: true is not implemented"
          end
          if on_uncovered == :prevent
            raise NotImplementedError,
              "on_uncovered: :prevent is not implemented"
          end
        end

        private

        def assert_known_option!(name, value, allowed)
          return if allowed.include?(value)

          raise ArgumentError,
            "unknown #{name} #{value.inspect}, expected one of #{allowed.inspect}"
        end

        # Every dependency edge (dependent type -> provider type) is created by
        # a registration, so any cycle is completed by the registration of its
        # closing edge and can be detected there.
        def assert_acyclic!(type)
          adjacency = dependency_graph
          seen = Set.new
          stack = adjacency[type].dup

          until stack.empty?
            node = stack.pop
            next if seen.include?(node)
            if node == type
              raise CircularDependencyError,
                "circular prerequisite dependency involving #{type}"
            end
            seen << node
            stack.concat(adjacency[node])
          end
        end

        # Edges point from a dependent role type to the role types providing the
        # categories it depends on.
        def dependency_graph
          providers = provider_types_by_category

          Hash.new { |hash, key| hash[key] = [] }.tap do |graph|
            registry.grep(Dependency).each do |entry|
              graph[entry.type].concat(providers[entry.category])
            end
          end
        end

        def provider_types_by_category
          Hash.new { |hash, key| hash[key] = [] }.tap do |providers|
            registry.grep(Provider).each do |entry|
              providers[entry.category] << entry.type
            end
          end
        end
      end

      # Validity period that must be covered, nil if nothing is left to check.
      def prerequisite_check_period(validate_past)
        start_on = self.start_on || Date.current
        start_on = [start_on, Date.current].max unless validate_past
        end_on = self.end_on || FAR_FUTURE

        start_on..end_on if end_on >= start_on
      end

      def prerequisite_coverage(config)
        roles = ::Role.with_inactive
          .where(person_id: person_id, type: PrerequisiteRole.provider_type_names(config.category))
          .where.not(id: id)

        if config.scope == :layer
          roles = roles
            .joins(:group)
            .where(groups: {layer_group_id: group.layer_group_id})
        end

        periods = roles.pluck(:start_on, :end_on).map do |start, finish|
          (start || Date.current)..(finish || FAR_FUTURE)
        end
        PfadiDe::Role::Coverage.new(periods)
      end

      private

      def assert_prerequisite_coverage
        return if person.nil? || group.nil?

        self.class.dependent_role_configurations.each do |config|
          period = prerequisite_check_period(config.validate_past)
          next if period.nil?

          gap = prerequisite_coverage(config).uncovered_interval(period)
          next if gap.nil?

          add_uncovered_prerequisite_error(config, gap)
        end
      end

      def add_uncovered_prerequisite_error(config, gap)
        in_layer = config.scope == :layer
        error_type = in_layer ? :uncovered_prerequisite_in_layer : :uncovered_prerequisite
        errors.add(:base, error_type,
          roles: prerequisite_role_names(config.category),
          layer: group.layer_group.to_s,
          period: format_prerequisite_period(gap))
      end

      def prerequisite_role_names(category)
        connector = I18n.t("role.prerequisite.roles_connector")
        PrerequisiteRole.provider_type_names(category)
          .map { |name| name.safe_constantize&.model_name&.human || name }
          .to_sentence(two_words_connector: connector, last_word_connector: connector)
      end

      def format_prerequisite_period(range)
        from = I18n.l(range.begin)
        if range.end == FAR_FUTURE
          I18n.t("role.prerequisite.period_open", from: from)
        else
          I18n.t("role.prerequisite.period", from: from, to: I18n.l(range.end))
        end
      end
    end
  end
end
