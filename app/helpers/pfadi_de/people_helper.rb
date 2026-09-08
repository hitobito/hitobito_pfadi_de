# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe
  module PeopleHelper
    def restricted_attr?(person, attr)
      person.is_a?(Person) && person.self_or_managed_by?(current_user) &&
        PfadiDe::Person::SELF_OR_MANAGED_RESTRICTED_ATTRS.include?(attr.to_s)
    end
  end
end
