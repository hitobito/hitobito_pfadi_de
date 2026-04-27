# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::RolesController
  extend ActiveSupport::Concern

  prepended do
    helper_method :may_change_fee_kind?
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

  def may_change_fee_kind?
    entry.new_record? || change_type? || entry.type_changed?
  end

  def permitted_attrs(role_type = entry.class)
    super - (may_change_fee_kind? ? [] : [:fee_kind_id])
  end
end
