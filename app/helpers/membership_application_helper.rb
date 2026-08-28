# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module MembershipApplicationHelper
  def can_read_membership_application_attrs?(person)
    (current_ability.user_context.admin || current_user.root?) &&
      PfadiDe::Person::MEMBERSHIP_APPLICATION_ATTRS.any? { |attr| person.send(attr).present? }
  end
end
