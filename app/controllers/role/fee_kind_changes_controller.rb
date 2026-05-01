# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class Role::FeeKindChangesController < ApplicationController
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
      authorize!(:assign_restricted_fee_kinds, role) if fee_kind_change.to_restricted?
      save_and_redirect
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def save_and_redirect
    fee_kind_change.save!
    redirect_to group_person_path(role.group, role.person),
      notice: success_message(fee_kind_change.start_on)
  end

  def success_message(start_on)
    key = start_on.future? ? ".success_future_change" : ".success"
    t(key, fee_kind: fee_kind_change.new_fee_kind.to_s, start_on: I18n.l(start_on))
  end

  def redirect_unless_applicable
    unless role.fee_kind_type?
      redirect_to group_person_path(role.group, role.person),
        alert: t(".failure_role_does_not_allow_fee_kind")
    end
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
