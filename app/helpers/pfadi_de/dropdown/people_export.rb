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

      if groups.one?
        add_item(translate(:efz_antrag_label), antrag_path(groups.first))
      elsif groups.many?
        item = add_item(translate(:efz_antrag_label), "#")
        groups.each do |group|
          item.sub_items << Dropdown::Item.new(group.name_with_layer, antrag_path(group))
        end
      end
    end

    private

    def antrag_path(group) = template.group_person_efz_antrag_path(group, @user)

    def groups
      @groups ||= @user.roles.flat_map(&:group).uniq.map(&:decorate).sort_by(&:lft)
    end
  end
end
