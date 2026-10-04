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
      can :read, SepaMandate, group_id: readable_creditor_ids(user)
    end
  end

  private

  def readable_creditor_ids(user)
    context = AbilityDsl::UserContext.new(user)
    below_ids = context.permission_layer_ids(:layer_and_below_full)
    group_below_ids = context.permission_group_ids(:group_and_below_full) || []
    own_ids = (context.permission_layer_ids(:layer_full) || []) |
      (context.permission_layer_ids(:finance) || []) |
      (context.permission_group_ids(:group_full) || [])

    Group.where(id: own_ids)
      .or(Group.where(id: layers_below(below_ids | group_below_ids)))
      .where("groups.id = groups.layer_group_id")
      .select(:id)
  end

  def layers_below(root_ids)
    return [] if root_ids.blank?

    roots = Group.arel_table.alias("roots")
    Group
      .joins("INNER JOIN groups roots ON groups.lft >= roots.lft AND groups.rgt <= roots.rgt")
      .where(roots[:id].in(root_ids))
      .select(:id)
  end
end
