# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::Role::List
  def destroy
    @membership_restriction = :destroy
    super
  end

  def move
    @membership_restriction = :move
    super
  end

  def move_role(old_role, new_role)
    PfadiDe::Role::PrerequisiteCascade.deferred { super }
  end

  private

  def deleteable_roles
    super.each { |role| authorize_membership_restriction(role) }
  end

  def authorize_membership_restriction(role)
    restrictions = PfadiDe::MembershipRoleRestrictions.new(role, ability)
    return if membership_restriction_respected?(restrictions)

    raise CanCan::AccessDenied,
      I18n.t("role_lists.membership_#{@membership_restriction}_period_expired",
        person: role.person.full_name, days: restrictions.change_max_days)
  end

  def membership_restriction_respected?(restrictions)
    case @membership_restriction
    when :destroy then restrictions.destroyable?
    when :move then restrictions.group_or_type_changeable?
    else true
    end
  end
end
