# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::Contactable
  extend ActiveSupport::Concern

  BANK_ACCOUNT_ATTRS = [:bank_account_owner, :iban, :bic, :bank_name]

  included do
    Contactable::ACCESSIBLE_ATTRS += BANK_ACCOUNT_ATTRS
  end
end
