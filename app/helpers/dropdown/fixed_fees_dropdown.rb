# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class Dropdown::FixedFeesDropdown < Dropdown::Base
  # rubocop:disable Rails/HelperInstanceVariable
  #
  delegate :t, :new_group_invoice_list_path, to: :template

  def initialize(template, group)
    super(template, template.t(".invoice_button_dropdown"), :"money-bill-alt")
    @group = group
    init_items
  end

  def init_items
    Settings.invoice_lists.fixed_fees.each do |key, config|
      next if /membership/.match?(key)
      link = new_group_invoice_list_path(@group, fixed_fees: key)

      add_item(template.t(".invoice_button_#{key}"), link)
    end
  end
  # rubocop:enable Rails/HelperInstanceVariable
end
