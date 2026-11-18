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
    return if render_prerequisite_cascade_confirmation(model: full_entry_label) { preview_update }

    super
  end

  def destroy
    return if render_prerequisite_cascade_confirmation(model: full_entry_label) { preview_destroy }

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

  def preview_update
    @group = find_group
    role = Role.with_inactive.find(entry.id)
    change_type? ? preview_type_change(role) : preview_attribute_update(role)
  end

  def preview_type_change(role)
    return false unless membership_restrictions.group_or_type_changeable?

    new_role = build_new_type
    authorize!(:create, new_role)
    Roles::TypeChange.new(role, new_role).call
  end

  def preview_attribute_update(role)
    role.attributes = permitted_params
    PfadiDe::MembershipRoleRestrictions.new(role, current_ability).validate_changes && role.save
  end

  def preview_destroy
    role = Role.with_inactive.find(entry.id)
    PfadiDe::MembershipRoleRestrictions.new(role, current_ability).destroyable? && role.destroy
  end

  def provides_prerequisites?
    entry.class.provided_prerequisite_categories.any?
  end

  def last_primary_group_role_deleted
    super unless prerequisite_cascade_confirmation_rendered?
  end

  def create_new_role_and_destroy_old_role
    return reject_group_or_type_change unless membership_restrictions.group_or_type_changeable?

    super
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
