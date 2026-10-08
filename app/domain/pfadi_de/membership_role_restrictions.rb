# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class PfadiDe::MembershipRoleRestrictions
  attr_reader :role, :ability

  def self.change_max_days = Settings.role.change_membership_max_days

  def self.end_max_days = Settings.role.end_membership_max_days

  def self.earliest_end_on = end_max_days.days.ago.to_date

  delegate :change_max_days, :end_max_days, to: :class

  def initialize(role, ability)
    @role = role
    @ability = ability
  end

  def start_on_changeable? = can?(:update_start_on)

  def group_or_type_changeable? = can?(:update_group_or_type)

  def end_on_changeable? = can?(:update_end_on)

  def end_on_permitted?(date)
    date.nil? || date >= self.class.earliest_end_on || can?(:end_retroactively)
  end

  def destroyable?
    !role.destroy_removes_from_history? || can?(:hard_destroy)
  end

  def validate_changes
    validate_start_on
    validate_end_on
    role.errors.empty?
  end

  private

  def validate_start_on
    if role.will_save_change_to_start_on? && !start_on_changeable?
      role.errors.add(:start_on, :membership_change_period_expired, days: change_max_days)
    end
  end

  def validate_end_on
    return unless role.will_save_change_to_end_on?

    if !end_on_changeable?
      role.errors.add(:end_on, :membership_end_period_expired, days: change_max_days)
    elsif !end_on_permitted?(role.end_on)
      role.errors.add(:end_on, :too_far_in_past, days: end_max_days)
    end
  end

  def can?(action)
    ability.can?(action, stored_role)
  end

  def stored_role
    return role unless role.changed?

    @stored_role ||= Role.with_inactive.find(role.id)
  end
end
