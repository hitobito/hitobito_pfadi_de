# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module TableDisplays
  module People
    class SepaMandateColumn < TableDisplays::Column
      VALUE_METHODS = {
        payment_method: :payment_method_label,
        sepa_mandate_references: :sepa_mandate_references
      }.freeze

      def required_model_attrs(_attr) = []

      def required_model_includes(_attr) = [:active_sepa_mandates]

      def required_permission(_attr) = :show_details

      def sort_by(_attr) = nil

      def render(attr)
        super do |person|
          person.public_send(VALUE_METHODS.fetch(attr.to_sym))
        end
      end

      private

      def allowed_value_for(target, target_attr, &block)
        target.public_send(VALUE_METHODS.fetch(target_attr.to_sym))
      end
    end
  end
end
