# frozen_string_literal: true

#  Copyright (c) 2012-2025, BDP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

Fabrication.configure do |config|
  config.fabricator_path = ["spec/fabricators",
    "../hitobito_pfadi_de/spec/fabricators"]
  config.path_prefix = Rails.root
end
