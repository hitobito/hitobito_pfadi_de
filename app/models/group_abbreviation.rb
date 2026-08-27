# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class GroupAbbreviation < ActiveRecord::Base
  belongs_to :group, inverse_of: :abbreviations

  before_validation :downcase_value

  def to_s
    value
  end

  private

  def downcase_value
    self.value = value.to_s.strip.downcase.presence
  end
end
