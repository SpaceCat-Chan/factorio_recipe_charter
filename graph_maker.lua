local Recipe_List = require(arg[1])
---@type string
local OutputFilename = arg[2];

---@type string
local OutputResult = ""

local function Append(value)
	OutputResult = OutputResult..tostring(value)
end

local RecipeListToOutput = {}
local ItemsToOutput = {}
local RecipeToIgnore = {}
local ItemsToIgnore = {}
local RecipeListInCMD = {}
local ItemsInCMD = {}


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
	if not ChoiceBased or true then
		for _,Item in pairs(Recipe_List[RecipeName].ingredients) do
			WalkItemDepends(Item.name, ChoiceBased)
		end
	else
		print("Recipe: "..RecipeName.." uses the following items: ")
		for i,Ingredient in pairs(Recipe_List[RecipeName].ingredients) do
			print(tostring(i).." "..Ingredient.name)
		end
		local ToUse = {}
		local GotItRight = false
		repeat
			print("please enter the ones you want in binary format (001010 means number 4 and number 2)")
			local Result = io.read()
			if #Result ~= #(Recipe_List[RecipeName].ingredients) then
				print("wrong length")
			else
				for x=1,#Result do
					local Char = string.sub(Result, x, x)
					if Char == "1" then
						ToUse[x] = true
					elseif Char == "0" then
						ToUse[x] = false
					else
						print("bad char: "..Char)
						ToUse = {}
						break
					end
				end
				GotItRight = true
			end
		until GotItRight
		for i,Use in pairs(ToUse) do
			if not Use then
				ItemsToIgnore[Recipe_List[RecipeName].ingredients[i].name] = true
			end
		end
		for i,Use in pairs(ToUse) do
			if Use then
				WalkItemDepends(Recipe_List[RecipeName].ingredients[i].name, ChoiceBased)
			end
		end
	end
end

function WalkItemDepends(ItemName, ChoiceBased)
	if ItemsToIgnore[ItemName] then
		return
	end
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
		if ItemsToOutput[ItemName] then
			return
		end
		table.sort(FoundRecipies, function(a,b) return a.name < b.name end)
		local ToUse = {}
		if not (#FoundRecipies == 1 and FoundRecipies[1].name == ItemName) then
			print("")
			print("Item "..ItemName.." can be made with following recipies: ")
			for i,Recipe in ipairs(FoundRecipies) do
				print(tostring(i).." "..tostring(Recipe.name))
			end
			local GotItRight = false
			repeat
				print("please enter the ones you want in binary format (001010 means number 3 and number 5)")
				local Result = io.read()
				if #Result ~= #FoundRecipies then
					print("wrong length")
				else
					for x=1,#Result do
						local Char = string.sub(Result, x, x)
						if Char == "1" then
							ToUse[x] = true
						elseif Char == "0" then
							ToUse[x] = false
						else
							print("bad char: "..Char)
							ToUse = {}
							break
						end
					end
					GotItRight = true
				end
			until GotItRight
		else
			ToUse = {true}
		end
		ItemsToOutput[ItemName] = ToUse
		for i,Use in pairs(ToUse) do
			if not Use then
				RecipeToIgnore[FoundRecipies[i].name] = true
			end
		end
		for i,Use in pairs(ToUse) do
			if Use then
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