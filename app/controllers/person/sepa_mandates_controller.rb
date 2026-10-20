# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class Person::SepaMandatesController < CrudController
  self.nesting = Group, Person
  self.permitted_attrs = [:issued_at, :user_confirmed_evidence_exists]

  helper_method :creditor

  def new
    entry.issued_at = Time.zone.today
    super
  end

  def update
    entry.revoke!(current_person)
    redirect_to group_person_sepa_mandates_path(*parents),
      notice: t(".success", reference: entry.reference)
  end

  private

  def return_path
    super || index_path
  end

  def creditor
    @creditor ||= parents.first.layer_group
  end

  def list_entries
    super.includes(:group, :creator, :revoker)
      .accessible_by(SepaMandateReadables.new(current_person))
  end

  def build_entry
    super.tap do |mandate|
      mandate.group = creditor
      mandate.creator = current_person
    end
  end

  def authorize_class
    authorize!(:index, SepaMandate.new(person: parent, group: creditor))
  end
end
