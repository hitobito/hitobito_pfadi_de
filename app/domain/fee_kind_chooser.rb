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
    return nil unless role.class.has_fee_kind?
    return role.fee_kind if valid?(role)

    possible_for_role(role).first
  end

  def possible_for_role(role)
    return FeeKind.none unless role.class.has_fee_kind

    allowed_fee_kinds(layers: role.group.layer_group.hierarchy, role_type: role.type)
  end

  def possible_parents(layer)
    Role.types_with_fee_kind.flat_map do |role_type|
      allowed_fee_kinds(layers: layer.ancestors, role_type: role_type.name)
    end
  end

  private

  # Checks whether the pre-selected fee kind on a role is valid for that role.
  # This check is independent of the user's permissions or archival or rules about
  # present or absent parents or children. It just validates whether anyone ever
  # could have selected this fee kind for this role.
  def valid?(role)
    all_candidates(layers: role.group.layer_group.hierarchy, role_type: role.type).pluck(:id)
      .include?(role.fee_kind_id)
  end

  # Returns an ordered list of all fee kinds which fit the basic premises of the role:
  # The layer and the role type.
  def all_candidates(layers:, role_type:)
    FeeKind
      .where(layer: layers)
      .joins(:layer)
      .order(created_at: :asc)
      .includes(:layer)
      .to_a
      .select do |fee_kind| # TODO do this in SQL after hitobito_pfadi_de#52 is implemented
      FeeKind.root_fee_kind_of(fee_kind).role_type == role_type
    end
  end

  def current_candidates(layers:, role_type:)
    all_candidates(layers:, role_type:).select(&:not_archived?)
  end

  # Applies the full list of conditions on when fee kinds may be selected.
  def allowed_fee_kinds(layers:, role_type:)
    candidates = current_candidates(layers:, role_type:)

    lft_of_lowest_non_empty_layer = candidates.map(&:layer).map(&:lft).max

    candidates.reject do |fee_kind|
      # remove fee kinds from layers higher than necessary
      next true if fee_kind.layer.lft != lft_of_lowest_non_empty_layer

      # reject restricted kinds if the current user does not have the rights
      next fee_kind.restricted? unless @allow_restricted
    end
  end
end
