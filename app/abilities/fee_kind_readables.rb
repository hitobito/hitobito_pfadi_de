# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class FeeKindReadables < GroupReadables
  # self.same_group_permissions = [:group_full, :group_and_below_full]
  # self.above_group_permissions = [:group_and_below_full]
  # self.same_layer_permissions = [:layer_full, :layer_and_below_full]

  def initialize(ability)
    super(ability.user)
    @token = ability.try(:token) # some abilities have this

    can :index, FeeKind, accessible_fee_kinds
    can :index, FeeRate, accessible_fee_rates
  end

  private

  def accessible_fee_kinds
    return FeeKind.all if user.root?

    FeeKind.where(layer_id: layer_group_ids).where(archived_at: nil).distinct
  end

  def accessible_fee_rates
    return FeeRate.all if user.root?

    FeeRate.where(fee_kind: {layer_id: layer_group_ids}).valid_today
  end

  def layer_group_ids
    if @token&.fee_kinds?
      case @token.permission
      when "layer_full", "layer_read"
        [@token.layer_group_id]
      when "layer_and_below_read", "layer_and_below_full"
        layer = @token.layer
        Group.layers.where(lft: (layer.lft...layer.rgt)).select(:id)
      else
        []
      end
    else
      user_context.permission_layer_ids(:finance)
    end
  end
end
