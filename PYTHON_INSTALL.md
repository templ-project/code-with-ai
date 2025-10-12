# Python Implementation Installation Guide

## Prerequisites

- Python 3.11 or higher
- [uv](https://docs.astral.sh/uv/) - Modern Python package manager

## Installing uv

### macOS/Linux

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Windows

```powershell
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
```

## Installing CwAI Python CLI

### From Source (Development)

```bash
# Clone the repository
git clone https://github.com/templ-project/code-with-ai.git
cd code-with-ai

# Create virtual environment and install dependencies
uv venv
uv pip install -e ".[dev]"

# Run Python commands directly
./bin/cwai-install-py
./bin/cwai-create-feature-py --help

# Or activate the venv and use without uv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
python3 bin/cwai-install-py
python3 bin/cwai-create-feature-py --help
```

### Quick Usage (No Installation)

You can also run the Python scripts directly without installation:

```bash
# Ensure dependencies are available
uv venv && uv pip install click rich questionary python-dotenv

# Run commands
./bin/cwai-install-py
./bin/cwai-create-feature-py "My feature" --json
```

## Running Tests

```bash
# Run tests with pytest
uv run pytest

# Run tests with coverage
uv run pytest --cov=cwai --cov-report=term-missing
```

## Formatting and Linting

```bash
# Format code with Black
uv run black src/ tests/

# Lint with Ruff
uv run ruff check src/ tests/

# Fix linting issues automatically
uv run ruff check --fix src/ tests/
```

## Project Structure

```text
bin/
├── cwai-install.js          # Node.js install command
├── cwai-create-feature.js   # Node.js create-feature command
├── cwai-install-py          # Python install wrapper
└── cwai-create-feature-py   # Python create-feature wrapper

src/
├── commands/
│   ├── install.js           # Node.js install implementation
│   ├── install_py.py        # Python install implementation
│   ├── create-feature.js    # Node.js create-feature implementation
│   └── create_feature_py.py # Python create-feature implementation
└── utils/
    ├── helpers.js           # Node.js utilities
    ├── helpers_py.py        # Python utilities
    ├── logger.js            # Node.js logging
    ├── logger_py.py         # Python logging
    ├── issue-manager.js     # Node.js issue management
    └── issue_manager_py.py  # Python issue management

tests/
├── __init__.py
├── test_helpers.py
└── test_logger.py
```

Both Node.js and Python implementations coexist in the same folders, with Python files using `_py` suffix.

## Environment Variables

Both Python and Node.js versions use the same environment variables:

| Variable             | Default   | Description                                |
| -------------------- | --------- | ------------------------------------------ |
| `CWAI_SPECS_FOLDER`  | `specs`   | Root folder for feature specs              |
| `CWAI_ISSUE_MANAGER` | `localfs` | Issue manager type (`localfs` or `github`) |

Set these in `.env` or `.env.local` in your project root.

## Comparison with Node.js Implementation

Both implementations provide the same functionality:

| Feature               | Node.js | Python |
| --------------------- | ------- | ------ |
| Interactive installer | ✅      | ✅     |
| Feature creation      | ✅      | ✅     |
| LocalFS issue manager | ✅      | ✅     |
| GitHub issue manager  | ✅      | ✅     |
| Template copying      | ✅      | ✅     |
| Branch management     | ✅      | ✅     |
| JSON output           | ✅      | ✅     |

Choose the implementation that best fits your development environment.

## Troubleshooting

### Command not found after installation

Ensure uv's bin directory is in your PATH:

```bash
# Add to ~/.bashrc or ~/.zshrc
export PATH="$HOME/.local/bin:$PATH"
```

### Import errors

Make sure you've installed the package:

```bash
uv pip install -e .
```

### Git command failures

Ensure git is installed and configured:

```bash
git --version
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```
