# frozen_string_literal: true

require 'sidekiq/web'

NolotiroOrg::Application.routes.draw do
  ActiveAdmin.routes(self)

  scope '/api' do
    scope '/v1' do
      get '/ad/:id', format: 'json', to: 'api/v1#ad_show', as: 'apiv1_ad_show'
      get '/woeid/:id/:type', format: 'json', to: 'api/v1#woeid_show', as: 'apiv1_woeid_show'
      get '/woeid/list', format: 'json', to: 'api/v1#woeid_list', as: 'apiv1_woeid_list'
    end
  end

  devise_for :users, only: :omniauth_callbacks, controllers: { omniauth_callbacks: 'callbacks' }

  constraints locale: /#{I18n.available_locales.join("|")}/ do
    get '/locales/:locale', to: 'locales#show', as: :locale

    # i18n
    scope '(:locale)' do
      root 'woeid#show', defaults: { type: 'give' }

      # FIXME: type on ads#create instead of params
      # FIXME: nolotirov2 legacy - redirect from /es/ad/create
      resources :ads, path: 'ad',
                      path_names: { new: 'create' },
                      except: [:index, :show] do
        resources :comments, only: :create
        resources :reports, only: [:new, :create]
      end

      constraints(AdConstraint.new) do
        scope '/ad' do
          get '/:id', to: 'ads#legacy_show'
          get '/:id/:slug', to: 'ads#show', as: 'adslug'
          get '/edit/id/:id', to: 'ads#edit', as: 'ads_edit'
          post '/bump/id/:id', to: 'ads#bump', as: 'ads_bump'
          post '/change_status/id/:id',
               to: 'ads#change_status',
               as: 'ads_change_status'
          get '/listall/ad_type/:type(/status/:status)(/page/:page)',
              to: 'woeid#show',
              as: 'ads_listall'
          get '/listuser/id/:id(/type/:type)(/status/:status)(/page/:page)',
              to: 'users#listads',
              as: 'listads_user',
              constraints: { id: %r{[^/]+} }
        end

        # locations lists
        get '/woeid/:id/:type(/status/:status)(/page/:page)',
            to: 'woeid#show',
            as: 'ads_woeid',
            constraints: { id: /\d+/ }
      end

      # location change
      scope '/location' do
        get  '/change', to: 'location#ask', as: 'location_ask'
        get  '/change2', to: 'location#change', as: 'location_change'
        post '/change', to: 'location#list'
        post '/change2', to: 'location#change'
      end

      devise_for :users,
                 skip: [:omniauth_callbacks, :unlocks],
                 controllers: { registrations: 'registrations' },
                 path: 'user',
                 path_names: {
                   sign_up: 'register',
                   sign_in: 'login',
                   sign_out: 'logout',
                   password: 'reset'
                 }

      # friendships
      resources :friendships, only: [:create, :destroy]

      scope '/admin' do
        authenticate :user, ->(u) { u.admin? } do
          mount Sidekiq::Web, at: '/jobs'
        end
      end

      get '/user/edit/id/:id', to: redirect('/es/user/edit'), as: 'user_edit'
      get '/profile/:id',
          to: 'users#profile',
          as: 'profile',
          constraints: { id: %r{[^/]+} }

      # search
      get '/search', to: redirect(SearchUrlRewriter.new)

      # blocking
      resources :blockings, only: [:create, :destroy]

      # legacy messaging
      get '/messages/new', to: redirect(ConversationUrlRewriter.new)
      get '/messages/:id', to: redirect(ConversationUrlRewriter.new)
      get '/message/create/id_user_to/:user_id/subject/:subject',
          to: redirect(ConversationUrlRewriter.new)

      # messaging
      resources :conversations do
        member { delete 'trash' }
        collection { delete 'trash' }
      end

      # rss
      # nolotirov2 - legacy
      # FIX: las URLs legacy vienen asi
      # /en                     /rss/feed/woeid/766273                     /ad_type/give
      # Lo solucionamos en el nginx.conf y una configuracion para hacer el search and replace
      # http://stackoverflow.com/questions/22421522/nginx-rewrite-rule-for-replacing-space-whitespace-with-hyphen-and-convert-url-to
      scope '/rss' do
        get '/feed/woeid/:woeid/ad_type/:type', format: 'rss', to: 'rss#feed', as: 'rss_type'
      end

      scope '/page' do
        get '/faqs', to: 'page#faqs', as: 'faqs'
        get '/tos', to: redirect('/page/privacy')
        get '/about', to: 'page#about', as: 'about'
        get '/privacy', to: 'page#privacy', as: 'privacy'
        get '/legal', to: 'page#legal', as: 'legal'
        get '/translate', to: 'page#translate', as: 'translate'
      end

      # contact
      get '/contact', to: 'contact#new', as: 'contacts'
      post '/contact', to: 'contact#create'

      # dismissing
      resources :announcements, only: [] do
        resources :dismissals, only: :create
      end
    end
  end
end
