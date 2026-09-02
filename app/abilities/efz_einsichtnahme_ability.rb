# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class EfzEinsichtnahmeAbility < AbilityDsl::Base
  include AbilityDsl::Constraints::Group

  on(EfzEinsichtnahme) do
    permission(:group_read).may(:read).in_same_group
    permission(:group_and_below_read).may(:read).in_same_group_or_below
    permission(:layer_read).may(:read).may(:read).in_same_layer
    permission(:layer_and_below_read).may(:read).in_same_layer_or_below
    permission(:layer_and_below_full).may(:read).in_same_layer_or_below

    permission(:layer_and_below_efz).may(:create).in_same_layer_or_below
    permission(:delete_efz).may(:destroy).all
  end

  def group = subject.group
end
