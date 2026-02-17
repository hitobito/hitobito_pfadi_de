# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class FeeKindChooser
  def initialize(role, allow_restricted = false)
    @role = role
    @allow_restricted = allow_restricted
  end

  def default
    return @role.fee_kind if @role.fee_kind_id

    allowed_fee_kinds.first
  end

  def possible
    allowed_fee_kinds
  end

  private

  # This returns FeeKinds which have a parent with a non-matching role_type.
  # Therefore, it may include too many kinds. Also, this alone does not
  # cover all the edge-cases and requirements, see allowed_fee_kinds below.
  def potential_fee_kinds
    return FeeKind.none unless @role.class.has_fee_kind

    FeeKind
      .where(role_type: [@role.type, nil])
      .where(layer: @role.group.layer_group.hierarchy)
      .not_archived
      .joins(:layer).order("layer.lft DESC")
  end

  # Apply domain-rules for further limiting of the result set. The previously
  # created order should stay intact as we only remove items from the list.
  def allowed_fee_kinds
    potential_fee_kinds.reject do |fee_kind|
      # remove fee-kinds with non-matching role-types
      next true if FeeKind.root_fee_kind_of(fee_kind).role_type != @role.type

      # reject restricted kinds if the current user does not have the rights
      next fee_kind.restricted? unless @allow_restricted

      # do not reject the current layer, even if there may be child-fee_kinds
      next false if fee_kind.layer_id == @role.group.layer_group_id

      # remove non-leaf fee-kinds
      next true if FeeKind.where(parent_id: fee_kind.id).any?
    end
  end
end
