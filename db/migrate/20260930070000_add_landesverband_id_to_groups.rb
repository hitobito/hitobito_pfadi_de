# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class AddLandesverbandIdToGroups < ActiveRecord::Migration[7.1]
  def up
    add_column :groups, :landesverband_id, :integer
    add_index :groups, :landesverband_id

    execute <<~SQL.squish
      UPDATE groups AS stamm
      SET landesverband_id = landesverband.id
      FROM groups AS landesverband
      WHERE stamm.type = 'Group::Stamm'
        AND landesverband.type = 'Group::Landesverband'
        AND landesverband.lft < stamm.lft
        AND landesverband.rgt > stamm.rgt
    SQL
  end

  def down
    remove_column :groups, :landesverband_id
  end
end
