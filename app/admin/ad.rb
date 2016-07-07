# frozen_string_literal: true

ActiveAdmin.register Ad do
  controller do
    def scoped_collection
      super.recent_first
    end
  end

  permit_params :woeid_code, :type, :body, :title

  filter :title
  filter :body
  filter :user_username, as: :string
  filter :user_id, as: :string
  filter :woeid_code
  filter :type, as: :select, collection: [['Regalo', 1], ['Busco', 2]]
  filter :status, as: :select, collection: [['Disponible', 1], ['Reservado', 2], ['Entregado', 3]]
  filter :published_at

  index do
    selectable_column

    column(:title) { |ad| link_to ad.title, admin_ad_path(ad) }

    column :body

    column :user

    column(:type) do |ad|
      status_tag({ 'give' => 'green', 'want' => 'red' }[ad.type_class],
                 label: ad.type_class)
    end

    column(:status) do |ad|
      status_tag({ 'available' => 'green',
                   'booked' => 'orange',
                   'delivered' => 'red' }[ad.status_class],
                 label: ad.status_class)
    end

    column(:city, &:woeid_name_short)

    column(:published_at) { |ad| ad.published_at.strftime('%d/%m/%y %H:%M') }

    actions(defaults: false) do |ad|
      edit = link_to 'Editar', edit_admin_ad_path(ad)
      delete = link_to 'Eliminar', admin_ad_path(ad), method: :delete

      safe_join([edit, delete], ' ')
    end
  end

  form do |f|
    f.inputs do
      f.input :type, as: :select,
                     collection: [['give', 1], ['want', 2]],
                     include_blank: false
      f.input :title
      f.input :body
      f.input :woeid_code
    end

    f.actions
  end

  action_item :view, only: :show do
    link_to 'Ver en la web', ad_path(ad)
  end
end
