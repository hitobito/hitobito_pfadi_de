# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe
  class LandesverbandFinder
    def self.call(group)
      return nil if group.nil?

      group.self_and_ancestors.where(type: ::Group::Landesverband.sti_name).first&.id
    end
  end
end
