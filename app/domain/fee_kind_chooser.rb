# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class FeeKindChooser
  def initialize(allow_restricted: false)
    @allow_restricted = allow_restricted
  end

  def default(role)
    return role.fee_kind if role.fee_kind_id

    possible_for_role(role).first
  end

  def possible_for_role(role)
    return FeeKind.none unless role.class.has_fee_kind

    allowed_fee_kinds(layers: role.group.layer_group.hierarchy, role_type: role.type)
  end

  def possible_parents(layer)
    Role.all_types.select(&:has_fee_kind).flat_map do |role_type|
      allowed_fee_kinds(layers: layer.ancestors, role_type: role_type.name)
    end
  end

  private

  # This includes FeeKinds which have a parent with a non-matching role_type.
  # Therefore, it may include too many kinds. Also, this alone does not
  # cover all the edge-cases and requirements, see below.
  def potential_fee_kinds(layers:)
    FeeKind
      .where(layer: layers)
      .not_archived
      .joins(:layer)
      .order(created_at: :asc)
  end

  # This filters the raw list of fee kinds by role type, which is inherited
  # from the root of the fee kind parent hierarchy.
  # It still does not cover all requirements, see allowed_fee_kinds below.
  def matching_fee_kinds(layers:, role_type:)
    potential_fee_kinds(layers:).reject do |fee_kind|
      # remove fee kinds with non-matching role-types
      next true if FeeKind.root_fee_kind_of(fee_kind).role_type != role_type
    end
  end

  # Apply domain-rules for further limiting of the result set. The previously
  # created order should stay intact as we only remove items from the list.
  def allowed_fee_kinds(layers:, role_type:)
    matching = matching_fee_kinds(layers:, role_type:)
    lft_of_lowest_non_empty_layer = matching.map(&:layer).map(&:lft).max

    matching.reject do |fee_kind|
      # remove fee kinds from layers higher than necessary
      next true if fee_kind.layer.lft != lft_of_lowest_non_empty_layer

      # reject restricted kinds if the current user does not have the rights
      next fee_kind.restricted? unless @allow_restricted
    end
  end
end
