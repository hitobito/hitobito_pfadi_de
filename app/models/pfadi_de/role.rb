# frozen_string_literal: true

#  Copyright (c) 2012-2025, BDP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::Role
  extend ActiveSupport::Concern

  included do
    # A valid and up-to-date Führungszeugnis is required for this role
    class_attribute :sgbviii_required
    self.sgbviii_required = false
  end
end
