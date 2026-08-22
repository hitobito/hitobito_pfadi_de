# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe::MailingList
  extend ActiveSupport::Concern

  included do
    validate :assert_layer_suffix

    private

    def assert_layer_suffix
      return unless mail_name_changed?
      return if mail_name.blank?
      return if layer_group.blank?

      unless mail_name.to_s.downcase.end_with?(*valid_suffixes)
        errors.add(:mail_name, :must_end_with_layer_suffix, suffix: ".#{layer_group.id}")
      end
    end

    def valid_suffixes
      ([layer_group.id.to_s] + Array(layer_group.abbreviations)).map { |suffix| ".#{suffix}" }
    end

    def layer_group
      group.layer_group
    end
  end
end
