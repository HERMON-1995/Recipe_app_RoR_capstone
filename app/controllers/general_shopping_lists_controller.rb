class GeneralShoppingListsController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user
    @recipes = @user.recipes.includes(recipe_foods: :food)
    @general_food_list = @user.foods
    @shoppinglist = calculate_shopping_list
    @total_items = @shoppinglist.size
    @total_price = calculate_total_price
  end

  private

  def calculate_shopping_list
    shoppinglist_raw = {}

    @recipes.each do |recipe|
      recipe.recipe_foods.each do |recipe_food|
        food = recipe_food.food
        if shoppinglist_raw[food.id]
          shoppinglist_raw[food.id][:quantity] += recipe_food.quantity
        else
          shoppinglist_raw[food.id] = {
            food: food,
            quantity: recipe_food.quantity
          }
        end
      end
    end

    shoppinglist = []
    shoppinglist_raw.values.each do |recipe_food|
      general_food = @general_food_list.find_by(name: recipe_food[:food].name)
      if general_food.nil? || general_food.quantity < recipe_food[:quantity]
        quantity = recipe_food[:quantity] - (general_food&.quantity || 0)
        shoppinglist << {
          food: recipe_food[:food],
          quantity: quantity,
          price: (general_food&.price || 0) * quantity
        }
      end
    end

    shoppinglist
  end

  def calculate_total_price
    @shoppinglist.sum { |item| item[:price] }
  end
end
