# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::Dropdown
  module PeopleExport
    delegate :group_person_efz_antrag_path, to: :template

    def init_items
      super

      # only add eFZ Antrag items if rendering in a person context
      return unless person

      group = person.leading_layer
      add_item(translate(:efz_antrag_label), antrag_path(group)) if group
    end

    private

    def antrag_path(group) = template.group_person_efz_antrag_path(group, person)

    def person
      template.assigns["person"]
    end
  end
end
