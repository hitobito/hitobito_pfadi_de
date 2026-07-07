# frozen_string_literal: true

#  Copyright (c) 2012-2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

Rails.application.routes.draw do
  extend LanguageRouteScope

  language_scope do
    resources :roles do
      resources :fee_kind_changes, only: [:new, :create], module: :role
    end
    resources :groups do
      resources :people do
        resource :efz_antrag, only: [:show], module: :people
        resources :efz_einsichtnahmen, only: [:new, :create, :destroy]
      end
      resources :fee_kinds do
        resources :fee_rates
      end
    end
  end

  scope path: ApplicationResource.endpoint_namespace, module: :json_api,
    constraints: {format: "jsonapi"}, defaults: {format: "jsonapi"} do
    resources :fee_kinds, only: [:index, :show]
    resources :fee_rates, only: [:index, :show]
    resources :efz_einsichtnahmen, only: [:index, :show, :create, :destroy]
  end
end
