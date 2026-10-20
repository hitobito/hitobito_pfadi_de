# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class SepaMandateResource < ApplicationResource
  primary_endpoint "sepa_mandates", [:index, :show, :create, :update]

  self.acceptable_scopes += %w[sepa_mandates]
  self.readable_class = SepaMandateReadables

  with_options writable: false do
    attribute :created_at, :datetime
    attribute :updated_at, :datetime
    attribute :status, :string, filterable: false, sortable: false do
      @object.status.to_s
    end
    attribute :creator_id, :integer, filterable: false, sortable: false
    attribute :revoker_id, :integer, filterable: false, sortable: false
  end

  # Only settable on creation, a reference is generated if none is given.
  with_options writable: :creating? do
    attribute :reference, :string
    attribute :evidence, :string, readable: :show_evidence?
    attribute :group_id, :integer
    attribute :person_id, :integer
    attribute :issued_at, :datetime
    attribute :mandate_text_version, :integer, filterable: false, sortable: false
  end

  # Mandates are immutable, an update may only revoke them.
  attribute :revoked_at, :datetime, filterable: false, writable: :updating?

  belongs_to :group, writable: false
  belongs_to :person, writable: false
  belongs_to :creator, resource: PersonResource, writable: false
  belongs_to :revoker, resource: PersonResource, writable: false

  before_save :assign_creator, only: :create
  before_save :confirm_evidence, only: :create
  before_save :assign_revoker, only: :update

  filter :status, :string, single: true, only: [:eq] do
    eq do |scope, value|
      case value
      when "active" then scope.active
      when "revoked" then scope.revoked
      else scope.none
      end
    end
  end

  def base_scope
    super.list
  end

  private

  def show_evidence?(model)
    can?(:show_evidence, model)
  end

  # Without a model (e.g. for the schema), the attribute is reported as guarded.
  def creating?(model)
    model.nil? || model.new_record?
  end

  def updating?(model)
    model.nil? || model.persisted?
  end

  def authorize_create(model)
    invalid_request!(:person_id, :blank) if model.person_id.blank?
    invalid_request!(:group_id, :blank) if model.group_id.blank?
    super
  end

  def authorize_update(model)
    authorize!(:update, model.class.find(model.id))
    invalid_request!(:revoked_at, :blank) if model.revoked_at.blank?
  end

  def assign_creator(model)
    model.creator = current_ability.user if current_ability.user&.persisted?
  end

  def assign_revoker(model)
    model.revoker = current_ability.user if current_ability.user&.persisted?
  end

  # The web form requires an explicit confirmation checkbox; API clients accept this
  # contractually by calling the endpoint, so we set it implicitly here.
  def confirm_evidence(model)
    model.user_confirmed_evidence_exists = true
  end
end
