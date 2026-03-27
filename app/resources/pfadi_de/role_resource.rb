# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::RoleResource
  extend ActiveSupport::Concern

  prepended do
    attribute :fee_kind_id, :integer, writable: :on_create

    belongs_to :fee_kind, writable: false
  end

  def on_create(model_instance)
    model_instance.new_record?
  end
end
