local ollama = require("./src")

local session = ollama.new("192.168.8.132", 11434)

local history = {
	{
		role = "system",
		content = "You are a helpful assistant.",
	},
	{
		role = "user",
		content = "Hello! What is the time?",
	},
}

local response = session:Chat({
	model = "PetrosStav/gemma3-tools:12b",
	messages = history :: any,
	tools = {
		{
			name = "get_time",
			description = "Get the current time",
			parameters = {
				type = "object",
				properties = {},
			},
		},
	},
})

table.insert(history, response.message :: any)

if response.message.tool_calls then
	for _, tool_call in response.message.tool_calls do
		local name = tool_call["function"].name

		if name == "get_time" then
			local time = os.date("%H:%M:%S")

			table.insert(history, {
				role = "tool",
				content = time,
			})
		end
	end
end

local response = session:Chat({
	model = "PetrosStav/gemma3-tools:12b",
	messages = history :: any,
	tools = {
		{
			name = "get_time",
			description = "Get the current time",
			parameters = {
				type = "object",
				properties = {},
			},
		},
	},
})

print(response)
