# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::RolesController
  extend ActiveSupport::Concern

  prepended do
    helper_method :may_change_fee_kind?, :membership_restrictions

    before_update :validate_membership_role_changes
    before_destroy :assert_membership_role_destroyable
    before_render_form :restrict_group_selection
  end

  def create
    if params[:autosubmit].present?
      assign_attributes
      entry&.ensure_fee_kind
      render "new"
    else
      super
    end
  end

  def update
    if params[:autosubmit].present?
      if change_type?
        entry.attributes = build_new_type.attributes.except("id", "terminated")
      else
        assign_attributes
      end
      entry&.ensure_fee_kind
      render "edit"
    else
      super
    end
  end

  private

  def change_type
    return super if membership_restrictions.group_or_type_changeable?

    @new_role = build_new_type
    @new_role.errors.add(:base, :membership_group_or_type_change_period_expired,
      days: membership_restrictions.change_max_days)
    prepare_for_rerender_edit
    render :edit, status: :unprocessable_content
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
