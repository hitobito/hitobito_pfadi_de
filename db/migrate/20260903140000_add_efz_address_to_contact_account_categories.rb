# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class AddEfzAddressToContactAccountCategories < ActiveRecord::Migration[8.0]
  def up
    add_column :contact_account_categories, :efz_address, :boolean, default: false, null: false
    ContactAccountCategory.reset_column_information
    backfill_efz_address_flag
  end

  def down
    remove_column :contact_account_categories, :efz_address
  end

  private

  def backfill_efz_address_flag
    require_relative File.expand_path("../seeds/support/pfadi_de/contact_account_category_seeder.rb", __dir__)

    PfadiDe::ContactAccountCategorySeeder::CATEGORIES.each do |contact_account_type, contactable_types|
      contactable_types.each do |contactable_type, categories|
        categories.each do |attrs|
          next unless attrs[:efz_address]

          ContactAccountCategory
            .find_by!(contact_account_type: contact_account_type,
                     contactable_type: contactable_type,
                     key: attrs[:key])
            .update!(efz_address: true)
        end
      end
    end
  end
end
