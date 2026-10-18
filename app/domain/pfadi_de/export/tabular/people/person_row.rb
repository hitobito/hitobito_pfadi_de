#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::Export::Tabular::People::PersonRow
  extend ActiveSupport::Concern

  def leading_layer
    entry.leading_layer.to_s
  end
end
