#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PfadiDe::InvoiceAbility
  extend ActiveSupport::Concern

  included do
    on(FeeKind) do
      permission(:finance).may(:show, :index).in_layer
      permission(:finance).may(:new, :create, :edit, :update, :destroy).in_layer_if_active
    end

    on(FeeRate) do
      permission(:finance).may(:show, :index).in_layer
      permission(:finance).may(:new, :create, :edit, :update, :destroy).in_layer_if_active
    end
  end
end
