# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe
  module ContactAccountCategory
    extend ActiveSupport::Concern

    included do
      scope :efz_address, -> { where(efz_address: true) }

      validate :assert_efz_address_implies_unique_per_contactable
    end

    def efz_address?
      efz_address == true
    end

    private

    def assert_efz_address_implies_unique_per_contactable
      return unless efz_address? && !unique_per_contactable?

      errors.add(:unique_per_contactable, :required_when_efz_address,
        attribute: self.class.human_attribute_name(:efz_address))
    end
  end
end
