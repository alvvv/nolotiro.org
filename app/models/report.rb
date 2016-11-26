# frozen_string_literal: true

class Report < ActiveRecord::Base
  validates :ad, presence: true
  validates :reporter, presence: true, uniqueness: { scope: :ad }

  belongs_to :ad
  belongs_to :reporter, class_name: 'User'

  enum reason: [:scam, :spam]

  scope :recent, -> { where('reports.created_at > ?', 1.day.ago) }
end
