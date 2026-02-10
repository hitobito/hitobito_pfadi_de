# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

Fabricator(:fee_kind) do
  name do
    [
      Faker::Subscription.subscription_term,
      Faker::Subscription.plan
    ].join(" ")
  end

  layer { Group.roots.first }

  restricted do |attrs|
    false if attrs[:layer]&.parent.nil? # top_layer?
  end

  role_type do |attrs|
    "Group::Mitglieder::OrdentlicheMitgliedschaft" if attrs[:parent].nil?
  end
end
