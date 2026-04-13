# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::GroupDecorator
  extend ActiveSupport::Concern

  def show_new_period_invoice_template_for_groups?
    (type.constantize.child_types - [type.constantize]).any? { |type| type.layer? }
  end
end
