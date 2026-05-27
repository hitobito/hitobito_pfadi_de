# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class EfzEinsichtnahme < ActiveRecord::Base
  attr_accessor :confirmation

  belongs_to :person
  belongs_to :einsichtnehmer, class_name: "Person"

  validates_by_schema

  validates :person, :einsichtnehmer, :einsicht_on, :issued_on, presence: true
  validates :confirmation, acceptance: {allow_nil: false}

  has_paper_trail meta: {main_id: ->(e) { e.person_id }, main_type: Person.sti_name}

  after_commit :update_person_latest_efz_issued_on

  def to_s = I18n.l(einsicht_on)

  def group
    @group ||= Group.find(person.default_group_id)
  end

  private

  def update_person_latest_efz_issued_on
    person.update_column(:latest_efz_issued_on, person.efz_einsichtnahmen.maximum(:issued_on))
  end
end
