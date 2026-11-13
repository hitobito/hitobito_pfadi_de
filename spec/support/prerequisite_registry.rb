# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

RSpec.shared_context "with isolated prerequisite registry" do
  around do |example|
    registry = PfadiDe::Role::PrerequisiteRole
    providers = registry.providers.dup
    dependencies = registry.dependencies.dup
    example.run
    registry.providers.replace(providers)
    registry.dependencies.replace(dependencies)
  end
end
