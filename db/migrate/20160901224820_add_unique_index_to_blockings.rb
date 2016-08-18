# frozen_string_literal: true

class AddUniqueIndexToBlockings < ActiveRecord::Migration
  def change
    add_index :blockings, [:blocker_id, :blocked_id], unique: true
  end
end
