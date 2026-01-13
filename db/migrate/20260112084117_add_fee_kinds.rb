#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddFeeKinds < ActiveRecord::Migration[8.0]
  def change
    create_table :fee_kinds do |t|
      t.belongs_to :layer
      t.belongs_to :parent
      t.string :name
      t.string :role_type
      t.timestamps
    end
  end
end
