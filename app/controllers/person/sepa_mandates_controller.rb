# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class Person::SepaMandatesController < CrudController
  self.nesting = Group, Person
  self.permitted_attrs = [:issued_at, :valid_from, :confirmation]

  prepend_before_action :entry, only: :revoke

  helper_method :creditor

  def new
    entry.issued_at = Time.zone.today
    entry.valid_from = Time.zone.today
    super
  end

  def create
    super(location: group_person_sepa_mandates_path(*parents))
  end

  def revoke
    entry.revoke!(current_user)
    redirect_to group_person_sepa_mandates_path(*parents),
      notice: t(".success", reference: entry.reference)
  end

  def destroy
    super(location: group_person_sepa_mandates_path(*parents))
  end

  private

  def creditor
    @creditor ||= parents.first.layer_group
  end

  def list_entries
    super.includes(:group, :creator, :revoker).select { |mandate| can?(:show, mandate) }
  end

  def ivar_name(klass)
    super((klass == NilClass) ? model_class : klass)
  end

  def build_entry
    super.tap do |mandate|
      mandate.group = creditor
      mandate.creator = current_user
    end
  end

  def authorize_class
    authorize!(:index, SepaMandate.new(person: parent))
  end
end
