# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

class AddLiegenschaftAttributesToGroups < ActiveRecord::Migration[8.0]
  def change
    add_column :groups, :property_type, :string
    add_column :groups, :property_owner, :string
    add_column :groups, :property_facilities_sanitary, :boolean
    add_column :groups, :property_facilities_water, :boolean
    add_column :groups, :property_guests_interior, :integer
    add_column :groups, :property_campingarea, :integer
    add_column :groups, :rental_audience, :string
    add_column :groups, :rental_public_listing, :boolean
  end
end
