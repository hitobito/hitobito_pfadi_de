# frozen_string_literal: true

#  Copyright (c) 2025, BDP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::Person
  extend ActiveSupport::Concern

  prepended do
    Person::GENDERS.push("d")

    self.used_attributes -= [:company, :company_name]
  end

  def entry_date
    roles.with_inactive.first&.start_on
  end
end
