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

    # These has_many/belongs_to calls, and root_types below, all have to stay on
    # this base Group class rather than on an STI subclass such as Group::Stamm:
    # has_many/belongs_to write to the class_attribute :_reflections, and the
    # first such write on a subclass forks it away from Group's, permanently
    # hiding from that subclass any association Group registers afterwards.
    # root_types Group::Bundesebene, further down, triggers exactly that: it is
    # a bare constant reference that autoloads Group::Bundesebene, whose
    # `children Group::Landesverband` autoloads that, whose own `children`
    # autoloads Group::Bezirk and Group::Stamm in turn — all before this method
    # returns. So every has_many/belongs_to here must run before root_types, or
    # a subclass loaded by that cascade would fork its reflections too early to
    # see them.
    has_many :fee_kinds, inverse_of: :layer, dependent: :destroy
    has_many :fee_rates, through: :fee_kinds, dependent: :destroy

    has_many :abbreviations, class_name: "GroupAbbreviation", inverse_of: :group,
      dependent: :destroy
    accepts_nested_attributes_for :abbreviations, allow_destroy: true, reject_if: :all_blank

    # Only meaningful for Group::Stamm: the Landesverband it is in, possibly with
    # a Bezirk in between (computed here on new/moved Stamm groups; kept in sync
    # on a Bezirk's own move by Group::Bezirk#update_stamm_landesverband_ids).
    # Declared here rather than on Group::Stamm itself for the reason above.
    belongs_to :landesverband, class_name: "Group::Landesverband", optional: true
    validates :landesverband_id, presence: true, if: -> { instance_of?(Group::Stamm) }
    before_validation :set_landesverband_id,
      if: -> { instance_of?(Group::Stamm) && (new_record? || parent_id_changed?) }

    root_types Group::Bundesebene

    validates :iban, iban: true, on: :update, allow_blank: true

    paper_trail_options[:skip] << "landesverband_id"
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
