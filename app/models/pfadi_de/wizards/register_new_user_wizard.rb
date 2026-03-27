# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::Wizards::RegisterNewUserWizard
  extend ActiveSupport::Concern

  def person_attributes
    super.except("fee_kind_id")
  end

  def build_role(person)
    super.tap { |role| role.fee_kind_id = new_user_form.attributes["fee_kind_id"] }
  end
end
