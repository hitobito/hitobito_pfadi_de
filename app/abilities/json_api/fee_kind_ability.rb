# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class JsonApi::FeeKindAbility
  include CanCan::Ability

  def initialize(user)
    @user = user
    @user_context = AbilityDsl::UserContext.new(user)
    can :index, FeeKind, accessible_fee_kinds
    can :index, FeeRate, accessible_fee_rates
  end

  private

  def accessible_fee_kinds
    return true if @user.root?

    {layer_id: layer_group_ids, archived_at: nil}
  end

  def accessible_fee_rates
    return true if @user.root?

    {
      fee_kind: {layer_id: layer_group_ids, archived_at: nil},
      valid_from: ..Time.zone.today, valid_until: [nil, Time.zone.today..]
    }
  end

  def layer_group_ids
    @user_context.permission_layer_ids(:finance)
  end
end
