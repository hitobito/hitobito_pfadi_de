# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::SelfRegistrationResource
  extend ActiveSupport::Concern

  prepended do
    with_options filterable: false, sortable: false do
      attribute :fee_kind_id, :integer, writable: true, readable: false
    end

    before_attributes :extract_role_attributes
  end

  def extract_role_attributes(attributes)
    @fee_kind_id = attributes.delete(:fee_kind_id)
  end

  def build_role(model)
    super.tap { |role| role.fee_kind_id = @fee_kind_id }
    @fee_kind_id = nil
  end
end
