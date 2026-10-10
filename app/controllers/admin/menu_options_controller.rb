module Admin
  class MenuOptionsController < BaseController
    before_action :set_menu_option, only: [ :edit, :update, :destroy ]

    def index
      @menu_options = MenuOption.ordered
      @counts = Guest.where.not(menu_option_id: nil).group(:menu_option_id).count
    end

    def new
      @menu_option = MenuOption.new(sort_order: (MenuOption.maximum(:sort_order) || 0) + 1)
    end

    def create
      @menu_option = MenuOption.new(menu_option_params)
      if @menu_option.save
        redirect_to admin_menu_options_path, notice: "Menu option created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @menu_option.update(menu_option_params)
        redirect_to admin_menu_options_path, notice: "Menu option updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @menu_option.destroy
        redirect_to admin_menu_options_path, notice: "Menu option deleted."
      else
        redirect_to admin_menu_options_path, alert: "Guests have already chosen #{@menu_option.name}. Hide it instead of deleting it."
      end
    end

    private

    def set_menu_option
      @menu_option = MenuOption.find(params[:id])
    end

    def menu_option_params
      params.require(:menu_option).permit(:name, :description, :sort_order, :active)
    end
  end
end
