# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  setup do
    @ad = create(:ad)
    @user = create(:user, email: 'jaimito@example.com', username: 'jaimito')
    @admin = create(:admin)
  end

  test 'has unique usernames' do
    user1 = build(:user, username: 'Username')
    assert user1.save

    user2 = build(:user, username: 'Username')
    assert_not user2.save
    assert_includes user2.errors[:username], 'ya está en uso'
  end

  test 'has unique case insensitive usernames' do
    user1 = build(:user, username: 'Username')
    assert user1.save

    user2 = build(:user, username: 'username')
    assert_not user2.save
    assert_includes user2.errors[:username], 'ya está en uso'
  end

  test 'disallows usernames that look like emails' do
    user = build(:user, username: 'larryfoster@example.com')

    assert_not user.valid?
    assert_includes user.errors[:username], 'no es válido'
  end

  test 'disallows usernames that look like ids' do
    user1 = build(:user, username: '007')
    assert user1.valid?

    user2 = build(:user, username: '12345')
    assert_not user2.valid?
    assert_includes user2.errors[:username], 'no es válido'
  end

  test 'disallows usernames containing URL separator character' do
    user = build(:user, username: 'elena/mario')
    assert_not user.valid?
  end

  test 'has unique emails' do
    user1 = build(:user, email: 'larryfoster@example.com')
    assert user1.save

    user2 = build(:user, email: 'larryfoster@example.com')
    assert_not user2.save
    assert_includes user2.errors[:email], 'ya está en uso'
  end

  test 'saves downcased emails' do
    user1 = build(:user, email: 'Larryfoster@example.com')
    assert user1.save
    assert_equal 'larryfoster@example.com', user1.email
  end

  test 'has passwords no shorter than 5 characters' do
    @user.password = '1234'
    assert_not @user.valid?
    assert_includes @user.errors[:password],
                    'es demasiado corto (5 caracteres mínimo)'

    @user.password = '12345'
    assert @user.valid?
  end

  test 'has non-empty usernames' do
    @user.username = ''
    assert_not @user.valid?
    assert_includes @user.errors[:username], 'no puede estar en blanco'
  end

  test 'has usernames no longer than 63 characters' do
    @user.username = 'A' * 63
    assert @user.valid?

    @user.username = 'A' * 64
    assert_not @user.valid?
    assert_includes @user.errors[:username],
                    'es demasiado largo (63 caracteres máximo)'
  end

  test '.recently_received_reports counts user received reports' do
    ad = create(:ad, user: @user)
    another_ad = create(:ad, user: @user)
    assert_empty @user.recently_received_reports

    create(:report, ad: ad)
    create(:report, ad: ad, created_at: 2.days.ago)
    assert_equal 1, @user.recently_received_reports.size

    create(:report, ad: another_ad)
    assert_equal 2, @user.recently_received_reports.size
  end

  test '.recently_received_reports counts user received reports' do
    create(:report, ad: create(:ad, user: @user))

    assert_equal 1, @user.recently_received_reports.size
  end

  test '.recently_received_reports ignores old reports' do
    create(:report, ad: create(:ad, user: @user), created_at: 2.days.ago)

    assert_empty @user.recently_received_reports
  end

  test '.recently_received_reports aggregates reports from different ads' do
    create(:report, ad: create(:ad, user: @user))
    create(:report, ad: create(:ad, user: @user))

    assert_equal 2, @user.recently_received_reports.size
  end

  test 'roles work' do
    assert_equal false, @user.admin?
    assert_equal true, @admin.admin?
  end

  test 'banning works' do
    @user.ban!
    assert_equal true, @user.banned?
  end

  test 'unbanning works' do
    @user.ban!
    @user.unban!
    assert_equal false, @user.banned?
  end

  test 'toogling banned flag works' do
    @user.ban!
    @user.moderate!
    assert_equal false, @user.banned?
  end

  test 'requires confirmation for new users' do
    user = create(:non_confirmed_user)
    assert_equal false, user.active_for_authentication?
  end

  test 'associated ads are deleted when user is deleted' do
    create(:ad, user: @user)

    assert_difference(-> { Ad.count }, -1) { @user.destroy }
  end

  test 'associated comments are deleted when user is deleted' do
    create(:comment, user: @user)

    assert_difference(-> { Comment.count }, -1) { @user.destroy }
  end

  test 'associated blockings are deleted when user is deleted' do
    create(:blocking, blocker: @user)

    assert_difference(-> { Blocking.count }, -1) { @user.destroy }
  end

  test 'associated incoming blockings are deleted when user is deleted' do
    create(:blocking, blocked: @user)

    assert_difference(-> { Blocking.count }, -1) { @user.destroy }
  end

  test 'associated friendships are deleted when user is deleted' do
    create(:friendship, user: @user)

    assert_difference(-> { Friendship.count }, -1) { @user.destroy }
  end

  test 'associated incoming friendships are deleted when user is deleted' do
    create(:friendship, friend: @user)

    assert_difference(-> { Friendship.count }, -1) { @user.destroy }
  end
end
