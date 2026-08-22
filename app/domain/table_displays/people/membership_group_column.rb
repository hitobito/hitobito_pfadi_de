# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module TableDisplays
  module People
    # The layer group (Stamm/Land/Bund) in which a person is primarily
    # active: their active legal membership role (Ordentliche
    # Mitgliedschaft or Foerdermitgliedschaft, as defined by the BdP/DPSG
    # bylaws), or, absent that, their longest-ongoing role of any type.
    # Labeled "Hauptgruppierung" in the UI. This is independent of
    # Person#primary_group (labeled "Standardgruppe"/"Standardebene" in this
    # wagon), which is a freely chosen, purely UX-related setting.
    #
    # Rendered as a link to the group's page on screen; export/API callers
    # get the plain group name (see #allowed_value_for).
    #
    # See Person#membership_group for the underlying resolution logic, also
    # used by the API.
    class MembershipGroupColumn < TableDisplays::Column
      def required_model_attrs(_attr) = []

      def required_model_includes(_attr) = {roles: {group: :layer_group}}

      def render(attr)
        super { |person| person.membership_group }
      end

      def required_permission(_attr) = :show

      # not backed by a database column, so it cannot be sorted on
      def sort_by(_attr) = nil

      private

      def allowed_value_for(target, _target_attr, &block)
        group = target.membership_group
        return unless group

        # template is nil during export (and lacks view helpers in plain
        # Ruby contexts like background jobs), where a plain string is needed
        if template.respond_to?(:link_to) && template.respond_to?(:group_path)
          template.link_to(group.to_s, template.group_path(group))
        else
          group.to_s
        end
      end
    end
  end
end
