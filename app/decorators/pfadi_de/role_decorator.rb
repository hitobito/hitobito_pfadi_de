# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::RoleDecorator
  extend ActiveSupport::Concern

  def for_history
    return super unless tentative_membership?
    "#{super} (#{Person.human_attribute_name(:tentative_membership)})".html_safe
  end

  private

  def tentative_membership?
    return false unless fee_kind_type?
    return false unless person.tentative_membership?
    return false if person.last_entry_date_with_fee_kind.nil?
    return false if start_on.nil?
    return false if person.last_entry_date_with_fee_kind <= start_on

    true
  end
end
