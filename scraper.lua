local Recipe_List = {}

for Name,Recipe in pairs(game.recipe_prototypes) do
	Recipe_List[Name] = {}
	Recipe_List[Name].ingredients = Recipe.ingredients
	Recipe_List[Name].products = Recipe.products
	Recipe_List[Name].main_product = Recipe.main_product
	Recipe_List[Name].name = Recipe.name
end

local player
if game.player then
	player = game.player.index
end

game.write_file("scraped_result.lua", serpent.block(Recipe_List), false, player)