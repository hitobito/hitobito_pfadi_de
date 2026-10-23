# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::RoleListsController
  include PfadiDe::PrerequisiteCascadeConfirmation

  def destroy
    return if provides_prerequisites? && confirm_prerequisite_cascade { simulate(:destroy) }

    super
  end

  def update
    return if provides_prerequisites? && confirm_prerequisite_cascade { simulate(:move) }

    super
  end

  private

  def provides_prerequisites?
    params.dig(:role, :types)&.keys.to_a.any? do |type|
      type.safe_constantize&.try(:provided_prerequisite_categories).present?
    end
  end

  def simulate(action)
    role_list.public_send(action)
  ensure
    @role_list = nil
  end
end
