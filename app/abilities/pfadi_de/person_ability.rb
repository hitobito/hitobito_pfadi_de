# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

module PfadiDe::PersonAbility
  extend ActiveSupport::Concern

  prepended do
    on(Person) do
      general(:index_messages).herself_or_admin
    end
  end

  def herself_or_admin
    herself || if_admin
  end
end
