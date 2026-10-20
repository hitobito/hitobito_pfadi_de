# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::PrerequisiteCascadeConfirmation
  private

  # Renders a confirmation of the dependent roles the block would shorten or
  # delete, unless the request is already confirmed. Returns whether it did.
  def confirm_prerequisite_cascade(&)
    return false if params[:prerequisite_cascade_confirmed].present? || !request.format.html?

    @prerequisite_changes = PfadiDe::Role::PrerequisiteCascade.preview(&)
    return false if @prerequisite_changes.empty?

    render "prerequisite_cascades/confirm", status: :unprocessable_content
    true
  end
end
