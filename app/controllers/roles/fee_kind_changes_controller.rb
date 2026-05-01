# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class Roles::FeeKindChangesController < ApplicationController
  helper_method :role, :fee_kind_change, :entry
  helper_method :may_change_fee_kind?

  before_action :redirect_unless_applicable
  before_action :load_group # needed for sheets

  def new
    authorize!(:update, role)
  end

  def create
    authorize!(:update, role)
    if fee_kind_change.valid?
      fee_kind_change.save!
      redirect_to person_path(role.person, format: :html), # unsure why we need html here
        notice: success_message(fee_kind_change.start_on)
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def success_message(start_on)
    key = start_on.future? ? ".success_future_change" : ".success"
    t(key, fee_kind: role.reload.fee_kind.to_s, start_on: I18n.l(start_on))
  end

  def redirect_unless_applicable
    alert = if !role.fee_kind
      t(".failure_role_misses_fee_kind")
    elsif fee_kind_change.changes_restricted? && !can?(:assign_restricted_fee_kinds, role)
      t(".failure_requires_assign_restricted_permission")
    end

    redirect_to person_path(role.person), alert: alert if alert
  end

  def fee_kind_change
    @fee_kind_change ||= Role::FeeKindChange.new(role, model_params)
  end

  def model_params = params[:role_fee_kind_change]&.permit(:start_on, :fee_kind_id)

  def role = @role ||= Role.find(params[:role_id])

  def load_group = @group = role.group

  def may_change_fee_kind? = true

  alias_method :entry, :fee_kind_change
end
