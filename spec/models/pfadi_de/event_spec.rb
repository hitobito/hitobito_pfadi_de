# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe Event do
  describe "address.company feature gate" do
    # possible_contact_attrs is built once at class-load time, so the disabled
    # state can only be tested in a wagon that boots with the feature
    # disabled like the `pfadi_de` wagon, not in the core
    # (settings.yml: address.company.enabled: false)
    it "excludes company_name from possible_contact_attrs" do
      expect(Event.possible_contact_attrs).not_to include(:company_name)
    end
  end
end
