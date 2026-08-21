# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module TableDisplays
  module People
    # See Person#leading_layer for the resolution logic.
    class LeadingLayerColumn < TableDisplays::Column
      def required_model_attrs(_attr) = []

      def required_model_includes(_attr) = {roles: {group: :layer_group}}

      def render(attr)
        super { |person| person.leading_layer }
      end

      def required_permission(_attr) = :show

      def sort_by(_attr) = nil

      private

      def allowed_value_for(target, _target_attr, &block)
        group = target.leading_layer
        return unless group

        # template is nil during export, where a plain string is needed
        if template.respond_to?(:link_to) && template.respond_to?(:group_path)
          template.link_to(group.to_s, template.group_path(group))
        else
          group.to_s
        end
      end
    end
  end
end
