# frozen_string_literal: true

require 'test_helper'
require 'integration/concerns/geo'

class ChoosingLocationTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers
  include Geo

  it 'redirects there when user logged in and no location set' do
    login_as create(:user, :stateless)
    visit root_path

    assert_selector 'h1', text: 'Cambia tu ciudad'
  end

  it 'suggests locations matching name' do
    create(:town, :tenerife)
    create(:town, name: 'Tenerife',
                  id: 369_486,
                  _state: :magdalena,
                  _country: :colombia)

    choose_location('tenerife')

    assert_text 'Santa Cruz de Tenerife, Islas Canarias, España (0 anuncios)'
  end

  it 'shows a message when no matching locations are found' do
    choose_location('tenerifa')

    assert_text 'No se han encontrado ubicaciones con el nombre tenerifa'
  end

  it 'shows an error message when submitted without a search' do
    choose_location('')

    assert_text 'No se han encontrado ubicaciones con el nombre'
  end

  it 'chooses between locations matching name' do
    create(:town, :tenerife)
    create(:town, name: 'Tenerife',
                  id: 369_486,
                  _state: :magdalena,
                  _country: :colombia)

    choose_location('tenerife')

    select 'Santa Cruz de Tenerife, Islas Canarias, España (0 anuncios)'
    click_button 'Elige tu ubicación'

    assert_location_page 'Santa Cruz de Tenerife, Islas Canarias, España'
  end

  it "directly chooses location when there's a single match" do
    create(:town, :tenerife)
    choose_location('tenerife, islas canarias')

    assert_location_page 'Santa Cruz de Tenerife, Islas Canarias, España'
  end

  it 'directly chooses location through GET request' do
    create(:town, :tenerife)
    visit location_change_path(location: 'tenerife, islas canarias')

    assert_location_page 'Santa Cruz de Tenerife, Islas Canarias, España'
  end

  it 'memorizes chosen location in the user' do
    create(:town, :tenerife)
    user = create(:user)
    login_as user
    choose_location('tenerife, islas canarias')
    logout
    login_as user

    assert_location_page 'Santa Cruz de Tenerife, Islas Canarias, España'

    logout
  end

  private

  def choose_location(name)
    visit location_ask_path
    fill_in 'location', with: name
    click_button 'Enviar'
  end
end
