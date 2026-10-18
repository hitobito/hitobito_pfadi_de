# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class JsonApi::SepaMandateAbility
  include CanCan::Ability

  def initialize(user)
    if user.root?
      can :read, SepaMandate
    else
      can :read, SepaMandate, person_id: user.id
      can :read, SepaMandate, group_id: finance_layer_ids(user)
    end
  end

  private

  def finance_layer_ids(user) = AbilityDsl::UserContext.new(user).permission_layer_ids(:finance)
end
