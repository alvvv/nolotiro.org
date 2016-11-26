# frozen_string_literal: true

class User < ActiveRecord::Base
  prepend Baneable
  include Statable

  counter_stats_for :created_at

  has_many :identities, inverse_of: :user, dependent: :destroy

  has_many :ads, foreign_key: :user_owner, dependent: :destroy
  has_many :comments, foreign_key: :user_owner, dependent: :destroy

  has_many :reports, foreign_key: :reporter_id, dependent: :destroy
  has_many :reported_ads,
           foreign_key: :reporter_id,
           source: :ad,
           through: :reports

  has_many :recently_received_reports,
           -> { merge(Report.recent) },
           source: :reports,
           through: :ads

  has_many :friendships, dependent: :destroy
  has_many :incoming_friendships, foreign_key: :friend_id,
                                  class_name: 'Friendship',
                                  dependent: :destroy
  has_many :friends, through: :friendships

  has_many :receipts, foreign_key: :receiver_id, dependent: :destroy

  has_many :blockings, foreign_key: :blocker_id, dependent: :destroy
  has_many :received_blockings, foreign_key: :blocked_id,
                                class_name: 'Blocking',
                                dependent: :destroy
  has_many :dismissals, dependent: :destroy

  has_many :started_conversations,
           foreign_key: :originator_id,
           class_name: 'Conversation',
           dependent: :nullify

  has_many :received_conversations,
           foreign_key: :recipient_id,
           class_name: 'Conversation',
           dependent: :nullify

  has_many :sent_messages,
           foreign_key: :sender_id,
           class_name: 'Message',
           dependent: :nullify

  validates :username, presence: true
  validates :username,
            uniqueness: { case_sensitive: false },
            format: { without: %r{\A([^@]+@[^@]+|[1-9]+|.*/.*)\z} },
            length: { maximum: 63 },
            allow_blank: true,
            if: :username_changed?

  validates :email, presence: true
  validates :email, uniqueness: true,
                    format: { with: /\A[^@]+@[^@]+\z/ },
                    allow_blank: true,
                    if: :email_changed?

  validates :password, presence: true,
                       confirmation: true,
                       if: :password_required?

  validates :password, length: { in: 5..128 }, allow_blank: true

  # Include default devise modules. Others available are:
  # :timeoutable and :omniauthable
  devise :confirmable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :lockable,
         :omniauthable, omniauth_providers: [:facebook, :google]

  scope :top_overall, -> do
    Rails.cache.fetch("top-overall-#{Ad.cache_digest}") { build_rank(Ad) }
  end

  scope :top_last_week, -> do
    key = "top-last-week-#{Ad.cache_digest}"

    Rails.cache.fetch(key) { build_rank(Ad.last_week) }
  end

  scope :top_city_overall, ->(woeid) do
    key = "woeid/#{woeid}/top-overall-#{Ad.cache_digest}"

    Rails.cache.fetch(key) { build_rank(Ad.by_woeid_code(woeid)) }
  end

  scope :top_city_last_week, ->(woeid) do
    key = "woeid/#{woeid}/top-last-week-#{Ad.cache_digest}"

    Rails.cache.fetch(key) { build_rank(Ad.last_week.by_woeid_code(woeid)) }
  end

  scope :whitelisting, ->(user) do
    joined = joins <<-SQL.squish
      LEFT OUTER JOIN blockings
      ON blockings.blocker_id = users.id AND blockings.blocked_id = #{user.id}
    SQL

    joined.where(blockings: { blocker_id: nil })
  end

  def self.build_rank(ads_scope)
    joins(:ads)
      .merge(ads_scope.rank_by(:id, :username, :user_owner))
      .pluck(:id, :username, 'COUNT(user_owner) as n_ads')
  end

  def self.new_with_session(params, session)
    oauth_session = session['devise.omniauth_data']
    return super unless oauth_session

    oauth = OmniAuth::AuthHash.new(oauth_session)

    new do |u|
      u.email = params[:email] || oauth.info.email
      u.username = params[:username] || oauth.info.name
      u.identities.build(provider: oauth.provider, uid: oauth.uid)
      u.confirmed_at = Time.zone.now if oauth.info.email
    end
  end

  def password_required?
    (new_record? || password || password_confirmation) && identities.none?
  end

  def admin?
    role == 1
  end

  def friend?(user)
    friendships.find_by(friend_id: user.id)
  end

  def blocking?(user)
    blockings.find_by(blocked_id: user.id)
  end

  def whitelisting?(user)
    blocking?(user).nil?
  end

  # nolotirov2 legacy: auth migration - from zend md5 to devise
  # https://github.com/plataformatec/devise/wiki/How-To:-Migration-legacy-database
  def valid_password?(password)
    if legacy_password_hash.present?
      if ::Digest::MD5.hexdigest(password).upcase == legacy_password_hash.upcase
        self.password = password
        self.legacy_password_hash = nil
        save!
        true
      else
        false
      end
    else
      super
    end
  end

  def reset_password(*args)
    self.legacy_password_hash = nil
    super
  end

  def self.max_allowed_reports
    10
  end

  def too_many_reports?
    recently_received_reports.size > self.class.max_allowed_reports
  end
end
