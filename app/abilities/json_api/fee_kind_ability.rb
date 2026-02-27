# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class JsonApi::FeeKindAbility
  include CanCan::Ability

  def initialize(main_ability)
    can :index, FeeKind, readable_fee_kinds(main_ability)
    can :index, FeeRate, readable_fee_rates(main_ability)
  end

  private

  def readable_fee_kinds(main_ability)
    FeeKind.accessible_by(FeeKindReadables.new(main_ability)).unscope(:select)
  end

  def readable_fee_rates(main_ability)
    FeeRate.where(fee_kind_id: readable_fee_kinds(main_ability).pluck(:id))
  end
end
