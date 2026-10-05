# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

module PfadiDe::PersonAbility
  extend ActiveSupport::Concern

  prepended do
    on(Person) do
      general(:index_messages).herself_or_admin

      general(:create_tags).none

      for_self_or_manageds do
        permission(:any).may(:show_tags).herself
      end

      permission(:group_read).may(:show_tags).in_same_group
      permission(:group_and_below_read).may(:show_tags).in_same_group_or_below
      permission(:layer_read).may(:show_tags).in_same_layer
      permission(:layer_and_below_read).may(:show_tags).in_same_layer_or_visible_below
      permission(:see_invisible_from_above).may(:show_tags).in_same_layer_or_below
    end
  end

  def herself_or_admin
    herself || if_admin
  end
end
