# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

module PfadiDe::PrerequisiteCascadeConfirmation
  private

  def render_prerequisite_cascade_confirmation(**info_options, &)
    return false unless provides_prerequisites? && request.format.html?
    return false if params[:prerequisite_cascade_confirmed].present?

    @prerequisite_changes = PfadiDe::Role::PrerequisiteCascade.preview(&)
    return false if @prerequisite_changes.empty?

    @prerequisite_cascade_info = t(".prerequisite_cascade_info_html", **info_options)
    render_prerequisite_cascade_changes
    true
  end

  def render_prerequisite_cascade_changes
    if request.format.turbo_stream?
      render turbo_stream: turbo_stream.append("modal-placeholder",
        partial: "prerequisite_cascades/modal"), status: :unprocessable_content
    else
      render "prerequisite_cascades/confirm", status: :unprocessable_content
    end
  end

  def prerequisite_cascade_confirmation_rendered?
    @prerequisite_changes.present?
  end
end
