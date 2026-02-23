# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module JsonApi
  class FeeKindAbility
    include CanCan::Ability

    def initialize(main_ability)
      can :index, FeeKind, build_conditions(main_ability)
      can :index, FeeRate, {fee_kind: build_conditions(main_ability)}
    end

    private

    def build_conditions(main_ability)
      layer_group_ids = read_layer_ids(main_ability)
      {layer_id: layer_group_ids, archived_at: nil}
    end

    def read_layer_ids(main_ability)
      case main_ability
      when TokenAbility then [main_ability.token.layer.id] if main_ability.token.invoices?
      else main_ability.user_context.permission_layer_ids(:finance)
      end
    end
  end
end
