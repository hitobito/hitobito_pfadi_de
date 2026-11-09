# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::RoleAbility
  extend ActiveSupport::Concern

  MEMBERSHIP_RESTRICTION_ACTIONS = [
    :update_start_on,
    :update_group_or_type,
    :hard_destroy,
    :end_retroactively
  ].freeze

  RESTRICTED_ERFASSUNG_FUEHRUNGSZEUGNIS_TYPES = [
    Group::Stamm::ErfassungFuehrungszeugnis,
    Group::Bezirk::ErfassungFuehrungszeugnis,
    Group::Landesverband::ErfassungFuehrungszeugnis
  ].freeze

  prepended do
    on(Role) do
      permission(:any)
        .may(:update_start_on, :update_group_or_type, :hard_destroy)
        .not_membership_role_or_created_recently
      permission(:any).may(:end_retroactively).not_membership_role
      permission(:admin).may(*MEMBERSHIP_RESTRICTION_ACTIONS).all

      general(:create).require_relevant_create_permissions
    end
  end

  def not_membership_role
    !membership_role_types.include?(subject.type)
  end

  def not_membership_role_or_created_recently
    not_membership_role ||
      subject.created_at >= Settings.role.change_membership_max_days.days.ago.beginning_of_day
  end

  def require_relevant_create_permissions
    erfassung_fuehrungszeugnis_grantable?
  end

  def erfassung_fuehrungszeugnis_grantable?
    !RESTRICTED_ERFASSUNG_FUEHRUNGSZEUGNIS_TYPES.include?(subject.class) ||
      user_context.admin ||
      contains_any?(subject.group.upper_layer_hierarchy.collect(&:id),
        user_context.permission_layer_ids(:layer_and_below_full))
  end

  private

  def membership_role_types
    Role.all_types.select(&:membership_role).map(&:sti_name)
  end
end
