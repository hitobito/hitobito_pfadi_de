# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

task "db:seed" => ["pfadi_de:prepare_contact_account_category_seeder"]

namespace :pfadi_de do
  task prepare_contact_account_category_seeder: :environment do
    require Rails.root.join("db", "seeds", "support", "contact_account_category_seeder")
    require_relative "../../db/seeds/support/pfadi_de/contact_account_category_seeder"
    ContactAccountCategorySeeder.prepend(PfadiDe::ContactAccountCategorySeeder)
    ContactAccountCategorySeeder::CATEGORIES.replace(
      PfadiDe::ContactAccountCategorySeeder::CONTACT_ACCOUNT_CATEGORIES
    )

    # Map the old additional address label used for eFZ recipients to the new
    # efz_address category during category backfill.
    ContactAccountCategoryMigrationJob::LABEL_KEY_MAPPING["AdditionalAddress"]["Group"] =
      {efz_address: ["anschrift_efz"]}
  end
end
