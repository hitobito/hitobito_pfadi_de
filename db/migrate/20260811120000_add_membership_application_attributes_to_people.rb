# frozen_string_literal: true

#  Copyright (c) 2026, Bund der Pfadfinderinnen und Pfadfinder e.V. This file is part of
#  hitobito_bdp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_bdp

class AddMembershipApplicationAttributesToPeople < ActiveRecord::Migration[7.0]
  def change
    change_table(:people) do |t|
      t.text :membership_application_reasons
      t.text :membership_application_statement_stamm
      t.text :membership_application_statement_lv
      t.text :membership_application_statement_bund
      t.text :membership_application_process_data
      t.string :membership_application_uuid
    end
  end
end
