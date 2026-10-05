# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::Qualification
  extend ActiveSupport::Concern

  private

  def set_finish_at
    return unless start_at? && qualification_kind&.validity

    validity = qualification_kind.validity
    self.finish_at = validity.zero? ? start_at : start_at + validity.years - 1.day
  end
end
