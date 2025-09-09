# frozen_string_literal: true

#  Copyright (c) 2025, BDP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::GroupsController
  extend ActiveSupport::Concern

  def permitted_attrs
    super + PfadiDe::Contactable::BANK_ACCOUNT_ATTRS
  end
end
