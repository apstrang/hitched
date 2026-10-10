# Replaces the hard-coded Guest#meal_choice enum with menu options the
# couple can edit from the admin. Existing choices are carried over.
class CreateMenuOptions < ActiveRecord::Migration[8.0]
  LEGACY_CHOICES = { 1 => "Chicken", 2 => "Fish", 3 => "Vegetarian", 4 => "Vegan" }.freeze

  def up
    create_table :menu_options do |t|
      t.string :name, null: false
      t.text :description
      t.integer :sort_order, default: 0, null: false
      t.boolean :active, default: true, null: false
      t.timestamps
    end

    add_reference :guests, :menu_option, foreign_key: true

    LEGACY_CHOICES.each do |value, name|
      id = select_value(<<~SQL)
        INSERT INTO menu_options (name, sort_order, active, created_at, updated_at)
        VALUES (#{quote(name)}, #{value}, TRUE, NOW(), NOW()) RETURNING id
      SQL
      execute "UPDATE guests SET menu_option_id = #{id.to_i} WHERE meal_choice = #{value}"
    end

    remove_column :guests, :meal_choice
  end

  def down
    add_column :guests, :meal_choice, :integer, default: 0

    LEGACY_CHOICES.each do |value, name|
      execute <<~SQL
        UPDATE guests SET meal_choice = #{value}
        FROM menu_options
        WHERE menu_options.id = guests.menu_option_id AND menu_options.name = #{quote(name)}
      SQL
    end

    remove_reference :guests, :menu_option, foreign_key: true
    drop_table :menu_options
  end
end
