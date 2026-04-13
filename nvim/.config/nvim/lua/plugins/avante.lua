return {
    "yetone/avante.nvim",
    build = "make",
    enabled = false,
    event = "VeryLazy",
    version = false, -- Never set this value to "*"! Never!
    ---@module 'avante'
    ---@type avante.Config
    opts = {
        -- add any opts here
        -- this file can contain specific instructions for your project
        instructions_file = "avante.md",
        -- for example
        -- mode = "legacy",
        provider = "qgenie",
        providers = {
            copilot = {
                endpoint = "https://api.githubcopilot.com",
                proxy = nil,
                allow_insecure = false,
                timeout = 10 * 60 * 1000,
                max_completion_tokens = 1000000,
                reasoning_effort = "high",
                model = "claude-sonnet-4.5",
            },
            qgenie = {
                __inherited_from = "openai",
                endpoint = "https://qgenie-api.qualcomm.com/v1",
                api_key_name = "QGENIE_API_KEY",  -- set this env var to your QGenie API key
                model = "anthropic::claude-4-6-sonnet",
                timeout = 10 * 60 * 1000,
                max_tokens = 8096,
            },
        },
        rag_service = {
            enabled = true,
            host_mount = "/prj/qct/mlsys/markham/scratch/juliray",  -- mounts your home dir into the container (read-only)
            runner = "docker",               -- requires Docker
            image = "docker-registry.qualcomm.com/juliray/avante-rag-service:latest",
            -- LLM used by the RAG service for synthesis
            llm = {
                provider = "openai",           -- uses openai-compatible protocol
                endpoint = "https://qgenie-api.qualcomm.com/v1",
                api_key = "QGENIE_API_KEY",
                model = "anthropic::claude-3-7-sonnet",
            },

            -- Embedding model for indexing your code
            embed = {
                provider = "openai",           -- openai-compatible embeddings
                endpoint = "https://qgenie-api.qualcomm.com/v1",
                api_key = "QGENIE_API_KEY",
                model = "qwen3-embedding-0.6b",  -- check QGenie's available embedding models
            },
        },
        behavior = {
            -- for example
            auto_suggestions = false,
            auto_apply_diff_after_generation = false,
        },
        windows = {
            sidebar_header = {
                rounded = false, -- removes semicircle separaters from header, background for normal text did not match so it looked weird, possible to fix?
            },
        },
        selector = {
            provider = "snacks",
            provider_opts = {
                source = "git_files",
            },
        },
    },
    dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        --- The below dependencies are optional,
        -- "nvim-mini/mini.pick", -- for file_selector provider mini.pick
        -- "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
        -- "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
        -- "ibhagwan/fzf-lua", -- for file_selector provider fzf
        -- -- "stevearc/dressing.nvim", -- for input provider dressing
        -- "folke/snacks.nvim", -- for input provider snacks
        -- "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
        -- "zbirenbaum/copilot.lua", -- for providers='copilot'
        -- {
        --     -- support for image pasting
        --     "HakonHarnes/img-clip.nvim",
        --     event = "VeryLazy",
        --     opts = {
        --         -- recommended settings
        --         default = {
        --             embed_image_as_base64 = false,
        --             prompt_for_file_name = false,
        --             drag_and_drop = {
        --                 insert_mode = true,
        --             },
        --             -- required for Windows users
        --             use_absolute_path = true,
        --         },
        --     },
        -- },
        -- {
        --     -- Make sure to set this up properly if you have lazy=true
        --     'MeanderingProgrammer/render-markdown.nvim',
        --     opts = {
        --         file_types = { "markdown", "Avante" },
        --     },
        --     ft = { "markdown", "Avante" },
        -- },
    },
}
