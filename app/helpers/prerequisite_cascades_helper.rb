# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

module PrerequisiteCascadesHelper
  IGNORED_PARAMS = %w[authenticity_token _method].freeze

  def format_prerequisite_period(period)
    [period.begin, period.end]
      .map { |date| date ? l(date) : t("role.open_end") }
      .join(" – ")
  end

  def prerequisite_cascade_resubmit_fields
    hidden_fields_for(request.request_parameters.except(*IGNORED_PARAMS))
  end

  private

  def hidden_fields_for(value, name = nil)
    case value
    when Hash
      safe_join(value.map do |key, nested|
        hidden_fields_for(nested, name ? "#{name}[#{key}]" : key)
      end)
    when Array
      safe_join(value.map { |nested| hidden_fields_for(nested, "#{name}[]") })
    else
      hidden_field_tag(name, value, id: nil)
    end
  end
end
