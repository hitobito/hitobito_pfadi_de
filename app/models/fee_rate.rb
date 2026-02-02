# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class FeeRate < ApplicationRecord
  validates_by_schema

  belongs_to :fee_kind
  has_one :layer, through: :fee_kind

  scope :list, -> { order("valid_from DESC, valid_until DESC NULLS FIRST") }

  def to_s = name
end
