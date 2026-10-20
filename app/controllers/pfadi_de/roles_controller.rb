# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::RolesController
  extend ActiveSupport::Concern
  include PfadiDe::PrerequisiteCascadeConfirmation

  prepended do
    helper_method :may_change_fee_kind?, :membership_restrictions

    before_update :validate_membership_role_changes
    before_destroy :assert_membership_role_destroyable
    before_render_form :restrict_group_selection
  end

  def create
    return render_autosubmitted_new if params[:autosubmit].present?

    super
  end

  def update
    return render_autosubmitted_edit if params[:autosubmit].present?
    return if provides_prerequisites? && confirm_prerequisite_cascade { simulate_update }

    super
  end

  def destroy
    return if provides_prerequisites? && confirm_prerequisite_cascade { simulate_destroy }

    super
  end

  private

  def render_autosubmitted_new
    assign_attributes
    entry&.ensure_fee_kind
    render "new"
  end

  def render_autosubmitted_edit
    if change_type?
      entry.attributes = build_new_type.attributes.except("id", "terminated")
    else
      assign_attributes
    end
    entry&.ensure_fee_kind
    render "edit"
  end

  def simulate_update
    @group = find_group
    if change_type?
      create_new_role_and_destroy_old_role
    else
      assign_attributes
      with_callbacks(:update, :save) { save_entry }
    end
  ensure
    reset_simulated_entry
  end

  def simulate_destroy
    run_callbacks(:destroy) { entry.destroy }
  ensure
    reset_simulated_entry
  end

  def provides_prerequisites?
    entry.class.provided_prerequisite_categories.any?
  end

  def reset_simulated_entry
    @role = nil
    @new_role = nil
    @membership_restrictions = nil
  end

  def create_new_role_and_destroy_old_role
    return reject_group_or_type_change unless membership_restrictions.group_or_type_changeable?

    PfadiDe::Role::PrerequisiteCascade.deferred { super }
  end

  def reject_group_or_type_change
    @new_role = build_new_type
    @new_role.errors.add(:base, :membership_group_or_type_change_period_expired,
      days: membership_restrictions.change_max_days)
    false
  end

  def membership_restrictions
    @membership_restrictions ||= PfadiDe::MembershipRoleRestrictions.new(entry, current_ability)
  end

  def validate_membership_role_changes
    throw :abort unless membership_restrictions.validate_changes
  end

  def assert_membership_role_destroyable
    return if membership_restrictions.destroyable?

    entry.errors.add(:base, :membership_destroy_period_expired,
      days: membership_restrictions.change_max_days)
    throw :abort
  end

  def restrict_group_selection
    if entry.persisted? && !membership_restrictions.group_or_type_changeable?
      @group_selection = nil
    end
  end

  def may_change_fee_kind?
    entry.new_record? || change_type? || entry.type_changed?
  end

  def permitted_attrs(role_type = entry.class)
    super - (may_change_fee_kind? ? [] : [:fee_kind_id])
  end
end
