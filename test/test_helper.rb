# frozen_string_literal: true

#  Copyright (c) 2012-2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

# Configure Rails Environment
load File.expand_path("../../app_root.rb", __FILE__)
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../Gemfile", __FILE__)

require File.expand_path("test/test_helper.rb", ENV["APP_ROOT"])

class ActiveSupport::TestCase
  reset_fixture_path File.expand_path("../fixtures", __FILE__)
end
