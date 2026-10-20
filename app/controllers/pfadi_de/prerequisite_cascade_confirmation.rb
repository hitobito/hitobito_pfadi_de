# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

module PfadiDe::PrerequisiteCascadeConfirmation
  private

  # Renders a confirmation of the dependent roles the block would shorten or
  # delete, unless the request is already confirmed. Returns whether it did.
  def confirm_prerequisite_cascade(**info_options, &)
    return false if params[:prerequisite_cascade_confirmed].present? || !request.format.html?

    @prerequisite_changes = discarding_flash { PfadiDe::Role::PrerequisiteCascade.preview(&) }
    return false if @prerequisite_changes.empty?

    @prerequisite_cascade_info = t(".prerequisite_cascade_info_html", **info_options)
    render "prerequisite_cascades/confirm", status: :unprocessable_content
    true
  end

  def prerequisite_cascade_confirmation_rendered?
    @prerequisite_changes.present?
  end

  def discarding_flash
    original_flash = request.flash
    request.flash = ActionDispatch::Flash::FlashHash.new
    yield
  ensure
    request.flash = original_flash
  end
end
