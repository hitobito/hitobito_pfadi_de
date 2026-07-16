# frozen_string_literal: true

#  Copyright (c) 2012-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module People
  class EfzAntragsController < ApplicationController
    prepend Nestable
    include DryCrud::InstanceVariables

    self.nesting = [Group, Person]

    rescue_from Export::Pdf::EfzAntrag::TemplateNotFound, with: :handle_template_not_found

    def show
      group, person = parents
      authorize!(:show, person)
      pdf = Export::Pdf::EfzAntrag.new(group, person).generate
      send_data pdf, type: :pdf, disposition: :inline
    end

    private

    def handle_template_not_found
      group, person = parents
      redirect_to group_person_path(group, person), alert: t(".template_not_found")
    end
  end
end
