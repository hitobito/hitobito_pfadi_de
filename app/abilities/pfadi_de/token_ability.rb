# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::TokenAbility
  extend ActiveSupport::Concern

  private

  def define_token_abilities
    super

    if token.fee_kinds?
      define_fee_kind_abilities
      define_fee_rate_abilities
    end
  end

  def define_fee_kind_abilities
    can(:index, FeeKind) { |fk| token.layer.id == fk.layer_id }
    can(:show, FeeKind) { |fk| token.layer.id == fk.layer_id }
  end

  def define_fee_rate_abilities
    can(:index, FeeRate) { |fr| token.layer.id == fr.fee_kind.layer_id }
    can(:show, FeeRate) { |fr| token.layer.id == fr.fee_kind.layer_id }
  end
end
