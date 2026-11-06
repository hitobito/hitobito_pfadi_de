# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

module PfadiDe::Group
  extend ActiveSupport::Concern

  ABBREVIATION_ATTRS = [abbreviations_attributes: [:id, :value, :_destroy]]

  prepended do
    # Define additional used attributes
    # self.used_attributes += [:website, :bank_account, :description]
    # self.superior_attributes = [:bank_account]

    has_many :fee_kinds, inverse_of: :layer, dependent: :destroy
    has_many :fee_rates, through: :fee_kinds, dependent: :destroy
    has_many :sepa_mandates, dependent: :destroy

    has_many :abbreviations, class_name: "GroupAbbreviation", inverse_of: :group,
      dependent: :destroy
    accepts_nested_attributes_for :abbreviations, allow_destroy: true, reject_if: :all_blank

    belongs_to :landesverband, class_name: "Group::Landesverband"
    before_validation :set_landesverband_id,
      if: -> { instance_of?(Group::Stamm) && (new_record? || parent_id_changed?) }

    root_types Group::Bundesebene

    validates :iban, iban: true, on: :update, allow_blank: true

    paper_trail_options[:skip] |= ["landesverband_id"]
  end

  # For now, self registration is always disabled.
  def self_registration_active?
    false
  end

  private

  def set_landesverband_id
    self.landesverband_id = PfadiDe::LandesverbandFinder.call(parent)
  end
end
