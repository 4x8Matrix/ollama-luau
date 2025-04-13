local net = require("@lune/net")

--[=[
	@class Ollama
	@__index Prototype

	Implementation of the Ollama API in Luau. Specifically using the Lune Runtime. 

    :::caution
        This library doesn't support streaming, the Lune runtime does not support this feature.
    :::

    The API this library uses is documented here:
        - https://ollama.readthedocs.io/en/api/
]=]
local Ollama = {}

Ollama.Interface = {}
Ollama.Prototype = {}

--[=[
    @within Ollama

    List models that are currently loaded into memory.

    https://ollama.readthedocs.io/en/api/#list-running-models
]=]
function Ollama.Prototype.GetRunningModels(self: Instance)
	local request = net.request({
		url = `http://{self.url}:{self.port or 11434}/api/ps`,
		method = "GET",
	})

	return net.jsonDecode(request.body) :: {
		models: { RunningModel },
	}
end

--[=[
    @within Ollama

    Generate embeddings from a model

    https://ollama.readthedocs.io/en/api/#generate-embeddings
]=]
function Ollama.Prototype.GenerateEmbeddings(self: Instance, model: string, ...: string)
	local request = net.request({
		url = `http://{self.url}:{self.port or 11434}/api/embed`,
		method = "POST",
		body = net.jsonEncode({
			model = model,
			input = { ... },
		}),
	})

	return net.jsonDecode(request.body) :: {
		model: string,
		embeddings: { { number } },
		total_duration: number,
		load_duration: number,
		prompt_eval_count: number,
	}
end

--[=[
    @within Ollama

    Upload a model to a model library. Requires registering for ollama.ai and adding a public key first.

    https://ollama.readthedocs.io/en/api/#push-a-model
]=]
function Ollama.Prototype.PushModel(self: Instance, model: string, insecure: boolean)
	local request = net.request({
		url = `http://{self.url}:{self.port or 11434}/api/push`,
		method = "POST",
		body = net.jsonEncode({
			model = model,
			insecure = insecure,
			stream = false,
		}),
	})

	return net.jsonDecode(request.body) :: {
		status: string,
	}
end

--[=[
    @within Ollama

    Download a model from the ollama library. Cancelled pulls are resumed from where they left off, and
    multiple calls will share the same download progress.

    https://ollama.readthedocs.io/en/api/#pull-a-model
]=]
function Ollama.Prototype.PullModel(self: Instance, model: string, insecure: boolean)
	local request = net.request({
		url = `http://{self.url}:{self.port or 11434}/api/pull`,
		method = "POST",
		body = net.jsonEncode({
			model = model,
			insecure = insecure,
			stream = false,
		}),
	})

	return net.jsonDecode(request.body) :: {
		status: string,
	}
end

--[=[
    @within Ollama

    Delete a model and its data.

    https://ollama.readthedocs.io/en/api/#delete-a-model
]=]
function Ollama.Prototype.DeleteModel(self: Instance, model: string)
	local request = net.request({
		url = `http://{self.url}:{self.port or 11434}/api/delete`,
		method = "DELETE",
		body = net.jsonEncode({
			model = model,
		}),
	})

	return request.ok
end

--[=[
    @within Ollama

    Show information about a model including details, modelfile, template, parameters, license, system prompt.

    https://ollama.readthedocs.io/en/api/#show-model-information
]=]
function Ollama.Prototype.GetModelInformation(self: Instance, model: string, verbose: boolean?)
	local request = net.request({
		url = `http://{self.url}:{self.port or 11434}/api/show`,
		method = "POST",
		body = net.jsonEncode({
			model = model,
			verbose = verbose,
		}),
	})

	return net.jsonDecode(request.body) :: {
		modelfile: string,
		parameters: string,
		template: string,
		details: {
			parent_model: string,
			format: string,
			family: string,
			families: { string },
			parameter_size: string,
			quantization_level: string,
		},
		model_info: {
			[string]: string,
		},
	}
end

--[=[
    @within Ollama

    List models that are available locally.

    https://ollama.readthedocs.io/en/api/#list-local-models
]=]
function Ollama.Prototype.GetLocalModels(self: Instance)
	local request = net.request({
		url = `http://{self.url}:{self.port or 11434}/api/tags`,
		method = "GET",
	})

	return net.jsonDecode(request.body) :: {
		models: { Model },
	}
end

--[=[
    @within Ollama

    Copy a model. Creates a model with another name from an existing model.

    https://ollama.readthedocs.io/en/api/#copy-a-model
]=]
function Ollama.Prototype.CopyModel(self: Instance, source: string, destination: string)
	local request = net.request({
		url = `http://{self.url}:{self.port or 11434}/api/copy`,
		method = "POST",
		body = net.jsonEncode({
			source = source,
			destination = destination,
		}),
	})

	return request.ok
end

--[=[
    @within Ollama

    Create a model from a Modelfile. It is recommended to set modelfile to the content of the Modelfile rather than
    just set path.
    
    This is a requirement for remote create. Remote model creation must also create any file blobs, fields such as
    FROM and ADAPTER, explicitly with the server using Create a Blob and the value to the path indicated in the
    response.

    https://ollama.readthedocs.io/en/api/#create-a-model
]=]
function Ollama.Prototype.CreateModel(
	self: Instance,
	model: string,
	modelfile: string?,
	path: string?,
	quantize: (
		"q2_K"
		| "q3_K_L"
		| "q3_K_M"
		| "q3_K_S"
		| "q4_0"
		| "q4_1"
		| "q4_K_M"
		| "q4_K_S"
		| "q5_0"
		| "q5_1"
		| "q5_K_M"
		| "q5_K_S"
		| "q6_K"
		| "q8_0"
	)?
)
	local request = net.request({
		url = `http://{self.url}:{self.port or 11434}/api/create`,
		method = "POST",
		body = net.jsonEncode({
			model = model,
			modelfile = modelfile,
			stream = false,
			path = path,
			quantize = quantize,
		}),
	})

	return request.ok
end

--[=[
    @within Ollama

    Generate the next message in a chat with a provided model.
    The final response object will include statistics and additional data from the request.

    https://ollama.readthedocs.io/en/api/#generate-a-chat-completion
]=]
function Ollama.Prototype.Chat(
	self: Instance,
	parameters: {
		model: string,
		messages: { Message },
		tools: { Tool }?,
		format: "json"?,
		options: { [ModelFileParameter]: any }?,
		keep_alive: number?,
	}
)
	local ollamaTools = {}

	if parameters.tools then
		for _, tool in parameters.tools do
			table.insert(ollamaTools, {
				["type"] = "function",
				["function"] = {
					name = tool.name,
					description = tool.description,
					parameters = tool.parameters,
				},
			})
		end
	end

	local request = net.request({
		url = `http://{self.url}:{self.port or 11434}/api/chat`,
		method = "POST",
		body = net.jsonEncode({
			model = parameters.model,
			messages = parameters.messages,
			tools = parameters.tools and ollamaTools or nil,
			format = parameters.format,
			options = parameters.options,
			keep_alive = parameters.keep_alive,
			stream = false,
		}),
	})

	return net.jsonDecode(request.body) :: {
		model: string,
		created_at: string,
		message: {
			role: "assistant",
			content: string,
			images: { string }?,
			tool_calls: {
				{
					[string]: {
						name: string,
						arguments: {
							[string]: any,
						},
					},
				}
			}?,
		},
		done_reason: string,
		done: true,
		total_duration: number,
		load_duration: number,
		prompt_eval_count: number,
		prompt_eval_duration: number,
		eval_count: number,
		eval_duration: number,
	}
end

--[=[
    @within Ollama

    Generate a response for a given prompt with a provided model.
    The final response object will include statistics and additional data from the request.

    https://ollama.readthedocs.io/en/api/#generate-a-completion
]=]
function Ollama.Prototype.Generate(
	self: Instance,
	parameters: {
		model: string,
		prompt: string,
		suffix: string?,
		images: { string }?,
		format: "json"?,
		options: { [ModelFileParameter]: any }?,
		system: string?,
		template: unknown?,
		context: { number }?,
		raw: boolean?,
		keep_alive: number?,
	}
)
	local request = net.request({
		url = `http://{self.url}:{self.port or 11434}/api/generate`,
		method = "POST",
		body = net.jsonEncode({
			model = parameters.model,
			prompt = parameters.prompt,
			suffix = parameters.suffix,
			images = parameters.images,
			format = parameters.format,
			options = parameters.options,
			system = parameters.system,
			template = parameters.template,
			context = parameters.context,
			raw = parameters.raw,
			keep_alive = parameters.keep_alive,
			stream = false,
		}),
	})

	return net.jsonDecode(request.body) :: {
		model: string,
		created_at: string,
		response: string,
		done: boolean,
		done_reason: string?,
		context: { number },
		total_duration: number,
		load_duration: number,
		prompt_eval_count: number,
		prompt_eval_duration: number,
		eval_count: number,
		eval_duration: number,
	}
end

--[=[
    @within Ollama

    Will instantiate a new Ollama session/instance, it's through this instance you can then interact
    with the Ollama API.
]=]
function Ollama.Interface.new(url: string, port: number?): Instance
	local self = setmetatable(
		{
			url = url,
			port = port,
		} :: Instance,
		{ __index = Ollama.Prototype }
	)

	return self
end

type ModelFileParameter =
	"mirostat"
	| "mirostat_eta"
	| "mirostat_tau"
	| "num_ctx"
	| "repeat_last_n"
	| "repeat_penalty"
	| "temperature"
	| "seed"
	| "stop"
	| "tfs_z"
	| "num_predict"
	| "top_k"
	| "top_p"
	| "min_p"

type Tool = {
	name: string,
	description: string,
	parameters: {
		type: string,
		properties: {
			[string]: {
				type: string,
				description: string,
				enum: { string }?,
			},
		}?,
		required: { string }?,
	},
}

type Message = {
	role: "system" | "user" | "assistant" | "tool",
	content: string,
	images: { string }?,
	tool_calls: { string }?,
}

type Model = {
	name: string,
	model: string,
	size: number,
	digest: string,
	details: {
		parent_model: string,
		format: string,
		family: string,
		families: { string },
		parameter_size: string,
		quantization_level: string,
	},
}

type RunningModel = Model & {
	expires_at: string,
	size_vram: number,
}

export type Instance = typeof(Ollama.Prototype) & {
	url: string,
	port: number,
}

return Ollama.Interface
