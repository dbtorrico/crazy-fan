# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      ## OmniAuth (Google OAuth2 — sem senha)
      t.string :provider, null: false
      t.string :uid,      null: false

      ## Perfil
      t.string  :email,        null: false
      t.string  :nickname,     limit: 18
      t.boolean :nickname_set, null: false, default: false
      t.string  :avatar_url

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count,      default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      t.timestamps null: false
    end

    add_index :users, [ :provider, :uid ], unique: true
    add_index :users, :email,              unique: true
    add_index :users, :nickname,           unique: true
  end
end
