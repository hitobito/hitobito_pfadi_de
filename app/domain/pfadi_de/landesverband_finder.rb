# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe
  # Finds the nearest Group::Landesverband ancestor of a group, walking up the
  # `parent` association
  class LandesverbandFinder
    def self.call(group)
      while group
        return group.id if group.instance_of?(::Group::Landesverband)
        group = group.parent
      end
      nil
    end
  end
end
