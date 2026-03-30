# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class FeeKindResource < ApplicationResource
  primary_endpoint "fee_kinds", [:index, :show]

  self.readable_class = JsonApi::FeeKindAbility
  self.acceptable_scopes += %w[fee_kinds]

  attribute :name, :string
  attribute :layer_id, :integer
  attribute :parent_id, :integer
  attribute :role_type, :string
  attribute :restricted, :boolean

  belongs_to :layer, resource: GroupResource
  belongs_to :parent, resource: FeeKindResource

  has_many :fee_rates

  def index_ability
    JsonApi::FeeKindAbility.new(current_ability)
  end
end
