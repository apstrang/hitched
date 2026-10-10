class MenuOption < ApplicationRecord
  has_many :guests, dependent: :restrict_with_error

  validates :name, presence: true

  scope :ordered, -> { order(:sort_order, :name) }
  scope :active, -> { where(active: true) }
end
