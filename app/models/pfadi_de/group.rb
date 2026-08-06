# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

module PfadiDe::Group
  extend ActiveSupport::Concern

  prepended do
    # Define additional used attributes
    # self.used_attributes += [:website, :bank_account, :description]
    # self.superior_attributes = [:bank_account]

    root_types Group::Bundesebene

    validates :iban, iban: true, on: :update, allow_blank: true

    has_many :fee_kinds, inverse_of: :layer, dependent: :destroy
    has_many :fee_rates, through: :fee_kinds, dependent: :destroy
  end

  # For now, self registration is always disabled.
  def self_registration_active?
    false
  end
end
