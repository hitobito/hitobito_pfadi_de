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
    :update_end_on,
    :end_retroactively
  ].freeze

  prepended do
    on(Role) do
      permission(:any)
        .may(:update_start_on, :update_group_or_type, :hard_destroy)
        .not_membership_role_or_created_recently
      permission(:any).may(:update_end_on).not_membership_role_or_not_ended_long_ago
      permission(:any).may(:end_retroactively).not_membership_role
      permission(:admin).may(*MEMBERSHIP_RESTRICTION_ACTIONS).all
    end
  end

  def not_membership_role
    !membership_role_types.include?(subject.type)
  end

  def not_membership_role_or_created_recently
    not_membership_role ||
      subject.created_at >= Settings.role.change_membership_max_days.days.ago.beginning_of_day
  end

  def not_membership_role_or_not_ended_long_ago
    not_membership_role ||
      subject.end_on.nil? ||
      subject.end_on >= Settings.role.change_membership_max_days.days.ago.to_date
  end

  private

  def membership_role_types
    Role.all_types.select(&:membership_role).map(&:sti_name)
  end
end
