# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class SepaMandateAbility < AbilityDsl::Base
  include AbilityDsl::Constraints::Group

  on(SepaMandate) do
    permission(:any).may(:read).herself
    permission(:finance).may(:read).in_same_layer

    permission(:finance).may(:create).for_member_in_same_layer
    permission(:finance).may(:update).active_in_same_layer

    permission(:admin).may(:destroy, :show_evidence).all
  end

  def herself = subject.person_id == user.id

  def for_member_in_same_layer
    in_same_layer && subject.person.groups_hierarchy_ids.include?(group.id)
  end

  def active_in_same_layer = subject.active? && in_same_layer
end
