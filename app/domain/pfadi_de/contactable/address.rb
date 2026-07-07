# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

module PfadiDe::Contactable::Address
  def efz_full_address_without_name = full_address.join("\n").strip

  def efz_only_name = contactable_and_company_name.join(", ")
end
