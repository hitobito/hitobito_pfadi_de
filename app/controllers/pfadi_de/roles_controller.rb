# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::RolesController
  extend ActiveSupport::Concern

  def create
    if params[:autosubmit].present?
      assign_attributes
      entry&.ensure_fee_kind
      render "new"
    else
      super
    end
  end

  private

  def permitted_attrs
    super.tap do |attrs|
      entry.new_record? ? attrs : attrs - [:fee_kind_id]
    end
  end
end
