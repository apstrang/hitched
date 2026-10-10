class Guest < ApplicationRecord
  belongs_to :invite
  belongs_to :menu_option, optional: true
  has_many :rsvps, dependent: :destroy

  enum :reception_seating, { with_parents: 0, kids_area: 1 }, prefix: :seated

  scope :adults, -> { where(is_child: false) }
  scope :children, -> { where(is_child: true) }

  validates :first_name, presence: true

  before_save :clear_email_for_children

  def full_name
    [ first_name, last_name ].map(&:presence).compact.join(" ")
  end

  def meal_name
    menu_option&.name
  end

  def rsvp_for(event)
    rsvps.find_by(event: event)
  end

  private

  def clear_email_for_children
    self.email = nil if is_child?
  end
end
