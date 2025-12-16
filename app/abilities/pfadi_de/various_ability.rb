#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::VariousAbility
  extend ActiveSupport::Concern

  included do
    on(QualificationKind) do
      # Allow managing qualifications, even while there are no course kinds yet.
      class_side(:index).if_admin
      permission(:admin).may(:manage).all
    end
  end
end
