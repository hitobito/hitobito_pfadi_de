# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class SepaMandateAbility < AbilityDsl::Base
  include AbilityDsl::Constraints::Person

  on(SepaMandate) do
    permission(:any).may(:read).herself
    permission(:group_full).may(:read).in_creditor
    permission(:group_and_below_full).may(:read).in_creditor_or_above
    permission(:layer_full).may(:read).in_creditor
    permission(:layer_and_below_full).may(:read).in_creditor_or_above
    permission(:finance).may(:read).in_creditor
    permission(:finance).may(:create).for_member_in_creditor_or_above
    permission(:finance).may(:revoke).active_in_creditor_or_above

    permission(:layer_full).may(:revoke).active_in_creditor
    permission(:layer_and_below_full).may(:revoke).active_in_creditor_or_above

    permission(:admin).may(:destroy, :show_evidence).all
  end

  def person = subject.person

  # The permission being checked is either a group or a layer permission, and the
  # lookup for the other kind is empty, so it is safe to check both. Layer permissions
  # only match layer ids, so non-layer ancestors do no harm.
  def in_creditor = permission_in_groups?(creditor_ids) || permission_in_layers?(creditor_ids)

  def in_creditor_or_above
    permission_in_groups?(creditor_hierarchy_ids) || permission_in_layers?(creditor_hierarchy_ids)
  end

  def for_member_in_creditor_or_above
    creditor.present? && in_creditor_or_above &&
      person.groups_hierarchy_ids.include?(creditor.id)
  end

  def active_in_creditor
    subject.active? && creditor.present? && in_creditor
  end

  def active_in_creditor_or_above
    subject.active? && creditor.present? && in_creditor_or_above
  end

  private

  def creditor = subject.group

  def creditor_ids = creditor ? [creditor.id] : person.layer_group_ids

  def creditor_hierarchy_ids = creditor ? creditor.hierarchy.map(&:id) : person.groups_hierarchy_ids
end
