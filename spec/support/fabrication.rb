# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
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
  gender { "w" }
  street { Faker::Address.street_name }
  housenumber { Faker::Address.building_number }
  zip_code { Faker::Address.zip_code[0..4] }
  town { Faker::Address.city }
end

[Group::Bundesebene, Group::Landesverband].each do |group_type|
  Fabrication.manager[group_type.name.to_sym].process_block do
    street { GroupPflichtfelder::SITZANSCHRIFT[:street] }
    housenumber { GroupPflichtfelder::SITZANSCHRIFT[:housenumber] }
    zip_code { GroupPflichtfelder::SITZANSCHRIFT[:zip_code] }
    town { GroupPflichtfelder::SITZANSCHRIFT[:town] }
  end
end

Fabrication.manager[Group::Stamm.name.to_sym].process_block do
  street { GroupPflichtfelder::STAMM[:street] }
  housenumber { GroupPflichtfelder::STAMM[:housenumber] }
  zip_code { GroupPflichtfelder::STAMM[:zip_code] }
  town { GroupPflichtfelder::STAMM[:town] }
  stamm_typ { GroupPflichtfelder::STAMM[:stamm_typ] }
end
