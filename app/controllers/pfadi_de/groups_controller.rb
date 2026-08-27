# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::GroupsController
  extend ActiveSupport::Concern

  def permitted_attrs
    attrs = super + PfadiDe::Contactable::BANK_ACCOUNT_ATTRS
    attrs += PfadiDe::Group::ABBREVIATION_ATTRS if entry.layer? && can?(:modify_superior, entry)
    attrs
  end
end
