# Ollama-Luau
Implementation of the Ollama API in Luau. Specifically using the Lune Runtime. 

> This library doesn't support streaming, the Lune runtime does not support this feature.

The API this library uses is documented here:
    - https://ollama.readthedocs.io/en/api/

## Installation
Install this library using the pesde package manager: https://pesde.dev/

```bash
pesde add 4x8matrix/ollama
```

## Usage

```luau
local ollama = require("../lune_packages/ollama")

local instance = ollama.new("localhost")

-- used for generating text, use :chat if you want to chat with the model
local response = instance:generate({
    modek =  "llama3.2",
    prompt = "What is the meaning in life?",
})

print(response.response)
```