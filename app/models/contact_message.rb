class ContactMessage < ApplicationRecord
  validates :name, :email, :body, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :body, length: { maximum: 5000 }
end
