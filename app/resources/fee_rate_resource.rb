# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class FeeRateResource < ApplicationResource
  primary_endpoint "fee_rates", [:index, :show]

  attribute :name, :string
  attribute :amount, :float
  attribute :valid_from, :date
  attribute :valid_until, :date
  attribute :max_member_months, :integer
  attribute :max_age, :integer
  attribute :fee_kind_id, :integer

  belongs_to :fee_kind, resource: FeeKindResource

  def index_ability
    JsonApi::FeeKindAbility.new(current_ability)
  end

  def base_scope
    super.valid_today
  end
end
