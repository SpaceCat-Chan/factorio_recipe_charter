---@type table<string, Recipe>
local Recipe_List = require(string.gsub(arg[1], "%.lua$", ""))
---@type string
local OutputFilename = arg[2];

---@type string
local OutputResult = ""

local function Append(value)
	OutputResult = OutputResult..tostring(value)
end

---@class Recipe
---@field public name string
local AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA______________________________________AAAAAAAAAAAAAAAAAAA

---@type table<string, Recipe>
local RecipeListToOutput = {}
---@type table<string, boolean>
local ItemsToOutput = {}
---@type table<string, table<integer, boolean>>
local AlreadyAppearedItems = {}
---@type table<string, boolean>
local RecipeToIgnore = {}
---@type table<string, boolean>
local ItemsToIgnore = {}
---@type table<string, Recipe>
local RecipeListInCMD = {}
---@type table<string, boolean>
local ItemsInCMD = {}

function PrintRecipies(ItemName, Recipies, Detail, Selected)
	print("\n\n")
	print("item: "..ItemName.." has "..tostring(#Recipies).." recipes that can make it")
		for i,Recipe in pairs(Recipies) do
			local RecipeString = ""
			if Selected[i] then
				RecipeString = RecipeString.."\x1b[1;4m"
			end
			if RecipeListToOutput[Recipe.name] then
				RecipeString = RecipeString.."\x1b[32m"
			end
			if RecipeToIgnore[Recipe.name] then
				RecipeString = RecipeString.."\x1b[31m"
			end
			RecipeString = RecipeString..tostring(i).." "..Recipe.name
			RecipeString = RecipeString.." ("..Recipe.localised_name[1]..")"
			if RecipeListToOutput[Recipe.name] then
				RecipeString = RecipeString.." already accepted\x1b[0m"
			end
			if RecipeToIgnore[Recipe.name] then
				RecipeString = RecipeString.." already declined\x1b[0m"
			end
			if Selected[i] then
				RecipeString = RecipeString.."\x1b[22m\x1b[24m"
			end
			print(RecipeString)
			if Detail then
				print("Ingredients:")
				for j,Ingredient in pairs(Recipe.ingredients) do
					local IngredientString = ""
					if ItemsToOutput[Ingredient.name] then
						IngredientString = IngredientString.."\x1b[32m"
					end
					IngredientString = IngredientString..tostring(i).."."..tostring(j)
					IngredientString = IngredientString.." "..Ingredient.name
					IngredientString = IngredientString.." ("..tostring(Ingredient.amount)..")"
					if ItemsToOutput[Ingredient.name] then
						IngredientString = IngredientString.." already being made by other recipe\x1b[0m"
					end
					print(IngredientString)
				end
				print("Products:")
				for j,Product in pairs(Recipe.products) do
					local ProductString = tostring(i).."."..tostring(j)
					ProductString = ProductString.." "..Product.name
					ProductString = ProductString.." ("
					if Product.amount then
						ProductString = ProductString..tostring(Product.amount)
					else
						ProductString = ProductString..tostring(Product.amount_min).."-"
						ProductString = ProductString..tostring(Product.amount_max)
					end
					ProductString = ProductString..")"
					if Recipe.main_product and Product.name == Recipe.main_product.name then
						ProductString = ProductString.." (main product)"
					end
					print(ProductString)
				end
				print("")
			end
		end
end

function UserSelectRecipies(ItemName, Recipies)
	local CurrentlySelected = {}
	for i,_ in pairs(Recipies) do
		CurrentlySelected[i] = false
	end
	local InputFinished = false
	local DoDetailPrint = false
	repeat
		PrintRecipies(ItemName, Recipies, DoDetailPrint, CurrentlySelected)
		DoDetailPrint = false
		print("\nplease enter the number of the recipies you want to toggle selection for (comma sepperated list)\ny to approve of the current selection\nY to force current selection\ndetail or Detail to show ingredients and products")
		local Input = io.read()
		if Input == "detail" or Input == "Detail" then
			DoDetailPrint = true
		elseif Input == "y" then
			local AnyRecipiesSelected = false
			for _,Selected in pairs(CurrentlySelected) do
				AnyRecipiesSelected = AnyRecipiesSelected or Selected
			end
			for _,Recipe in pairs(Recipies) do
				AnyRecipiesSelected = AnyRecipiesSelected or RecipeListToOutput[Recipe.name]
			end
			if AnyRecipiesSelected then
				InputFinished = true
			else
				print("are you sure? there are no recipies to make this item if you accept now\ntype Y to accept anyways (must be capital Y)")
				local Accept = io.read()
				if Accept == "Y" then
					InputFinished = true
				end
			end
		elseif Input == "Y" then
			InputFinished = true
		else
			local Numbers = {}
			local FailedGettingInput = false
			for StringPart in string.gmatch(Input, "[^,]*") do
				local Number = tonumber(StringPart)
				if Number == nil then
					print(StringPart.." is not a valid number")
					FailedGettingInput = true
				end
				if Recipies[Number] == nil then
					print(StringPart.." is outside of the allowed range")
					FailedGettingInput = true
				end
				table.insert(Numbers, Number)
			end
			if not FailedGettingInput then
				for _,Index in pairs(Numbers) do
					CurrentlySelected[Index] = not CurrentlySelected[Index]
				end
			end
		end
	until InputFinished
	return CurrentlySelected
end



function WalkDepends(RecipeName, ChoiceBased)
	if RecipeToIgnore[RecipeName] then
		return
	end
	if RecipeListToOutput[RecipeName] then
		return
	end
	if Recipe_List[RecipeName] == nil then
		print("no recipe named "..RecipeName)
		return
	end
	RecipeListToOutput[RecipeName] = Recipe_List[RecipeName]
	for _,Item in pairs(Recipe_List[RecipeName].ingredients) do
		WalkItemDepends(Item.name, ChoiceBased)
		ItemsToOutput[Item.name] = true
	end
end

function WalkItemDepends(ItemName, ChoiceBased)
	if ItemsToIgnore[ItemName] then
		return
	end
	---@type table<string, Recipe>
	local FoundRecipies = {}
	for Name,Recipe in pairs(Recipe_List) do
		local FoundInResults = false
		for _,Product in pairs(Recipe.products) do
			if Product.name == ItemName then
				FoundInResults = true
				break
			end
		end
		if FoundInResults then
			table.insert(FoundRecipies, Recipe)
		end
	end
	if #FoundRecipies == 0 then
		print("unable to find any recipies that make "..ItemName)
		return
	end
	if not ChoiceBased then
		for _,Recipe in pairs(FoundRecipies) do
			WalkDepends(Recipe.name, ChoiceBased)
		end
	else
		if AlreadyAppearedItems[ItemName] then
			return
		end
		table.sort(FoundRecipies, function(a,b) return a.name < b.name end)
		---@type table<integer, boolean>
		local ToUse = {}
		if not (#FoundRecipies == 1 and FoundRecipies[1].name == ItemName) then
			ToUse = UserSelectRecipies(ItemName, FoundRecipies)
		else
			ToUse = {true}
		end
		AlreadyAppearedItems[ItemName] = ToUse
		for i,Use in pairs(ToUse) do
			if not Use then
				if RecipeListToOutput[FoundRecipies[i].name] == nil then
					RecipeToIgnore[FoundRecipies[i].name] = true
				end
			end
		end
		for i,Use in pairs(ToUse) do
			if Use then
				RecipeToIgnore[FoundRecipies[i].name] = nil
				WalkDepends(FoundRecipies[i].name, ChoiceBased)
			end
		end
	end
end

function WalkRDepends(RecipeName)

end

function WalkItemRDepends(ItemName)

end

arg[3] = arg[3] or "all"

for x=4,#arg do
	if string.match(arg[x], "^%-") then
		local Current = string.gsub(arg[x], "^%-", "")
		if string.match(Current, "%-recipe__$") then
			Current = string.gsub(Current, "%-recipe__$", "")
			RecipeToIgnore[Current] = true
		elseif string.match(Current, "%-item__$") then
			Current = string.gsub(Current, "%-item__$", "")
			ItemsToIgnore[Current] = true
		end
	else
		local Current = string.gsub(arg[x], "^\\%-", "-")
		if string.match(Current, "%-item__$") then
			Current = string.gsub(Current, "%-item__$", "")
			print("item: "..Current)
			ItemsInCMD[Current] = true
		elseif string.match(Current, "%-recipe__$") then
			Current = string.gsub(Current, "%-recipe__$", "")
			print("recipe: "..Current)
			RecipeListInCMD[Current] = Recipe_List[Current]
		else
			print("Invalid Arg: "..Current)
		end
	end
end

if arg[3] == "only" then
	RecipeListToOutput = RecipeListInCMD
	ItemsToOutput = ItemsInCMD
elseif arg[3] == "depends" then
	for Name,_ in pairs(RecipeListInCMD) do
		WalkDepends(Name)
	end
	for Name,_ in pairs(ItemsInCMD) do
		WalkItemDepends(Name)
	end
elseif arg[3] == "choice depends" then
	for Name,_ in pairs(RecipeListInCMD) do
		WalkDepends(Name, true)
	end
	for Name,_ in pairs(ItemsInCMD) do
		WalkItemDepends(Name, true)
	end
elseif arg[3] == "reverse depends" then
	print("not implemented")
	return -2
elseif arg[3] == "reverse choice depends" then
	print("not implemented")
	return -2
elseif arg[3] == "all depends" then
	print("not implemented")
	return -2
elseif arg[3] == "all choice depends" then
	print("not implemented")
	return -2
elseif arg[3] == "all" then
	RecipeListToOutput = Recipe_List
else
	print("invalid argument 3: "..arg[3])
	return -1
end




Append("strict digraph {\n\t")

local function AppendProduct(Name, Product, Main)
	Append("\""..Name.."-recipe__\"->\""..Product.name.."-item__\"")
	Append("[")
	if Main then
		Append("color=green ")
	end
	Append("label=\"")
	if Product.amount then
		Append("Amount: "..Product.amount.."\\n")
	else
		Append("Minimum Amount: "..Product.amount_min.."\\n")
		Append("Maximum Amount: "..Product.amount_max.."\\n")
	end
	if Product.probability then
		Append("Probability: "..Product.probability.."\\n")
	end
	if Product.type == "fluid" and Product.temperature then
		Append("Temperature: "..Product.temperature.."\\n")
	end
	if Product.catalyst_amount then
		Append("Catalyst Amount: "..Product.catalyst_amount.."\\n")
	end
	Append("\"]\n\t")
	if Product.type == "fluid" then
		Append("\""..Product.name.."-item__\" [color=blue]\n\t")
	end
end

local function AppendIngredient(Name, Ingredient)
	Append("\""..Ingredient.name.."-item__\"->\""..Name.."-recipe__\"")
	Append("[label=\"")

	Append("Amount: "..Ingredient.amount.."\\n")
	if Ingredient.catalyst_amount then
		Append("Catalyst Amount: "..Ingredient.catalyst_amount.."\\n")
	end
	if Ingredient.minimum_temperature then
		Append("Minimum Temperature: "..Ingredient.minimum_temperature.."\\n")
	end
	if Ingredient.maximum_temperature then
		Append("Maximum Temperature: "..Ingredient.maximum_temperature.."\\n")
	end

	Append("\"]\n\t")
	if Ingredient.type == "fluid" then
		Append("\""..Ingredient.name.."-item__\" [color=blue]\n\t")
	end
end

for Name,Recipe in pairs(RecipeListToOutput) do
	Append("\""..Name.."-recipe__\"\n\t")
	if Recipe.main_product then
		AppendProduct(Name, Recipe.main_product, true)
	end
	for _,product in pairs(Recipe.products) do
		AppendProduct(Name, product)
	end
	for _,Ingredient in pairs(Recipe.ingredients) do
		AppendIngredient(Name, Ingredient)
	end
end

Append("\n}\n")

local Output = io.open(OutputFilename, "w+")

Output:write(OutputResult)
Output:close()