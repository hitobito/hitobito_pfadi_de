# frozen_string_literal: true

#  Copyright (c) 2012-2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

load File.expand_path("../../app_root.rb", __FILE__)
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../Gemfile", __FILE__)

require File.join(ENV["APP_ROOT"], "spec", "spec_helper.rb")

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[HitobitoPfadiDe::Wagon.root.join("spec/support/**/*.rb")].sort.each do |f|
  # The test group types must be loaded in the correct order as there are inter-dependencies.
  # The loading order is hardcoded in `spec/support/group/0_base.rb`, so we load only this
  # specific file in the subdirectory.
  next if %r{spec/support/group/(?!0_base.rb)}.match?(f)
  require f
end

RSpec.configure do |config|
  config.fixture_paths = [File.expand_path("../fixtures", __FILE__)]
end
