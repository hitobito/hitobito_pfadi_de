# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::MailingListAbility
  extend ActiveSupport::Concern

  included do
    on(::MailingList) do
      permission(:layer_and_below_full)
        .may(:show, :index_subscriptions, :export_subscriptions)
        .in_same_layer_or_below
      permission(:layer_and_below_full)
        .may(:create, :update, :update_subscriptions, :destroy)
        .in_same_layer_or_below_if_active

      permission(:layer_and_below_read)
        .may(:show, :index_subscriptions, :export_subscriptions)
        .in_same_layer_or_below
    end
  end
end
