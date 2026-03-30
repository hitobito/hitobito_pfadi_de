# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::ApiScopeAbility
  extend ActiveSupport::Concern

  prepended do
    self::REQUIRED_SCOPES.merge!({
      FeeRate: :fee_kinds
    })
  end
end
