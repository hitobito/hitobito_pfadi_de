# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module TableDisplays
  module People
    class SepaMandateColumn < TableDisplays::Column
      def required_model_attrs(_attr) = []

      def required_model_includes(_attr) = [:active_sepa_mandates]

      def required_permission(_attr) = :show_full

      def sort_by(_attr) = nil

      def render(attr)
        super do |person|
          value_for_layer(person, attr)
        end
      end

      private

      def allowed_value_for(target, target_attr, &block)
        value_for_layer(target, target_attr)
      end

      def value_for_layer(person, attr)
        layer = template&.parent&.layer_group
        return unless layer

        case attr.to_sym
        when :payment_method then person.payment_method_label(layer)
        when :sepa_mandate_references then person.sepa_mandate_references(layer)
        end
      end
    end
  end
end
