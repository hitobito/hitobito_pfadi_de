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
      return if layer_group.root?

      if valid_suffixes.empty?
        errors.add(:mail_name, :layer_has_no_abbreviation)
      elsif !mail_name.to_s.downcase.end_with?(*valid_suffixes)
        errors.add(:mail_name, :must_end_with_abbreviation)
      end
    end

    def valid_suffixes
      layer_group.abbreviations.pluck(:value).map { |value| ".#{value}" }
    end

    def layer_group
      group.layer_group
    end
  end
end
