# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class EfzEinsichtnahmenController < CrudController
  self.nesting = [Group, Person]
  self.permitted_attrs = [:einsicht_on, :issued_on, :confirmation]

  def new
    entry.einsicht_on = Date.current
  end

  def create
    assign_attributes
    entry.einsichtnehmer = current_user

    if entry.valid? && entry.save
      redirect_to(
        group_person_path(*parents),
        notice: I18n.t("efz_einsichtnahmen.created", einsicht_on: I18n.l(entry.einsicht_on))
      )
    else
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    super(location: request.referer || group_person_path(*parents))
  end
end
