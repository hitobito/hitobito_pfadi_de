# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module FeeKindsHelper
  def format_fee_kind_parent_id(fee_kind)
    return nil if fee_kind.parent.blank?
    link_to fee_kind.parent.name, group_fee_kind_path(fee_kind.parent.layer, fee_kind.parent)
  end
end
