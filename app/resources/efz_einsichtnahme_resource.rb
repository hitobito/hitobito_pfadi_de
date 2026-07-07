# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class EfzEinsichtnahmeResource < ApplicationResource
  primary_endpoint "efz_einsichtnahmen", [:index, :show, :create, :destroy]

  self.acceptable_scopes += %w[efz_einsichtnahmen]
  self.readable_class = JsonApi::EfzEinsichtnahmeAbility

  with_options writable: false do
    attribute :created_at, :datetime
    attribute :updated_at, :datetime
  end

  with_options filterable: false, sortable: false do
    attribute :person_id, :integer, filterable: true
    attribute :einsichtnehmer_id, :integer
  end

  attribute :einsicht_on, :date
  attribute :issued_on, :date

  belongs_to :person, writable: false
  belongs_to :einsichtnehmer, resource: PersonResource, writable: false

  private

  def authorize_create(model)
    invalid_request!(:person_id, :blank) if model.person_id.blank?
    invalid_request!(:einsichtnehmer_id, :blank) if model.einsichtnehmer_id.blank?
    # The web form requires an explicit confirmation checkbox; API clients accept this
    # contractually by calling the endpoint, so we set it implicitly here.
    model.confirmation = true
    super
  end
end
