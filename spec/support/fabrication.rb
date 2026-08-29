# frozen_string_literal: true

#  Copyright (c) 2012-2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

Fabrication.configure do |config|
  config.fabricator_path = ["spec/fabricators",
    "../hitobito_pfadi_de/spec/fabricators"]
  config.path_prefix = Rails.root
end

Fabrication.manager.load_definitions if Fabrication.manager.empty?
Fabrication.manager[:person].process_block do
  # deterministic, and old enough not to match age restricted fee rates
  birthday { 30.years.ago.to_date }
  street { Faker::Address.street_name }
  housenumber { Faker::Address.building_number }
  zip_code { Faker::Address.zip_code[0..4] }
  town { Faker::Address.city }
end
