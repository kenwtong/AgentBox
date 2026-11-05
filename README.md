# AgentBox - Docker Agent Environment

A Docker environment for running [OpenCode](https://opencode.ai/) and [Pi](https://github.com/badlogic/pi-mono) coding agents against a shared development workspace.

Both agents run as a non-root user and retain their sessions, configuration, and authentication across container rebuilds.

## Requirements

- Docker Engine or Docker Desktop
- Docker Compose v2
- Bash (for the optional AgentBox CLI helper)

## Getting started

### 1. Clone the repository

```bash
git clone https://github.com/kenwtong/agentbox.git
cd agentbox
```

### 2. Configure environment variables

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env` and configure the following values:

| Variable | Description |
|---|---|
| `HOST_UID` | Host user ID |
| `HOST_GID` | Host group ID |
| `WORKSPACE_DIR` | Host directory mounted inside the container |

Get your user and group IDs:

```bash
id -u
id -g
```

Update `.env` with the returned values.

Example:

```dotenv
HOST_UID=1000
HOST_GID=1000
WORKSPACE_DIR=./workspace
```

**Why HOST_UID and HOST_GID?**

The container runs as the `node` user rather than root. Matching its UID and GID to your host user ensures files created inside the container are owned by your host user, avoiding workspace permission problems.

### 3. Configure your workspace

The workspace directory can be inside or outside the repository.

Examples:

```dotenv
# Workspace inside the repository
WORKSPACE_DIR=./workspace

# Directory alongside the repository
WORKSPACE_DIR=../projects

# Absolute path
WORKSPACE_DIR=/home/alice/projects
```

Relative paths are resolved from the Compose project directory.

Create the selected directory if it doesn't exist:

```bash
mkdir -p workspace
```

On Linux, ensure the directory belongs to your host user:

```bash
sudo chown -R "$(id -u):$(id -g)" workspace
```

Adjust the path if you're using a different workspace directory.

### 4. Build and start the container

```bash
docker compose up -d --build
```

### 5. Enter the container

```bash
docker compose exec agents bash
```

Your configured host workspace is available inside the container at:

```text
/workspace
```

Both OpenCode and Pi use this same directory.

## AgentBox CLI

AgentBox includes an optional Bash script that simplifies container management.

The `scripts/agentbox` helper lets you start, rebuild, and manage AgentBox without having to navigate to the repository directory or remember Docker Compose commands.

### Installation

From the root of your cloned AgentBox repository:

Make the script executable:

```bash
chmod +x scripts/agentbox
```

Optionally, create a symbolic link in your local executable directory:

```bash
mkdir -p ~/.local/bin

ln -sf "$(pwd)/scripts/agentbox" ~/.local/bin/agentbox
```

Ensure `~/.local/bin` is included in your `PATH`.

You can verify the installation with:

```bash
which agentbox
```

Once installed, the `agentbox` command can be run from anywhere.

### Commands

| Command | Description |
|---|---|
| `agentbox` | Start containers and enter the agents container |
| `agentbox up` | Same as `agentbox` |
| `agentbox build` | Rebuild the image, start containers, and enter the agents container |
| `agentbox shell` | Enter an already-running agents container |
| `agentbox restart` | Restart services |
| `agentbox stop` | Stop services |
| `agentbox down` | Stop and remove containers |

### Examples

Start AgentBox and enter the container:

```bash
agentbox
```

Rebuild after changing the Dockerfile or application dependencies:

```bash
agentbox build
```

Enter an already-running container:

```bash
agentbox shell
```

Stop AgentBox:

```bash
agentbox stop
```

The script automatically resolves its repository location, including when invoked through a symbolic link. It does not require the repository to be installed in a specific directory.

The script is a convenience wrapper around Docker Compose. All standard Docker Compose commands remain available.

## Using OpenCode

Start OpenCode:

```bash
opencode
```

Authenticate:

```bash
opencode auth login
```

Continue the most recent session:

```bash
opencode --continue
```

Resume a specific session:

```bash
opencode --session SESSION_ID
```

## Using Pi

Start Pi:

```bash
pi
```

Authenticate using Pi's `/login` command.

Continue the most recent session:

```bash
pi --continue
```

Browse previous sessions:

```bash
pi --resume
```

## Workspace

The host workspace is mounted at `/workspace` inside the container.

You can clone repositories directly into it:

```bash
cd /workspace

git clone https://github.com/OWNER/PROJECT.git

cd PROJECT
```

Start either agent:

```bash
opencode
```

Or:

```bash
pi
```

Both agents can access and modify the same files.

## Persistent storage

Docker manages the following named volumes:

| Volume | Contents |
|---|---|
| `opencode-data` | OpenCode sessions, database, authentication and logs |
| `opencode-config` | OpenCode configuration |
| `pi-data` | Pi sessions, settings and extensions |
| `git-config` | Git global configuration |

These volumes are independent of the container lifecycle.

They survive:

- Container restarts
- Container removal
- Image rebuilds
- Docker Compose restarts

List volumes:

```bash
docker volume ls
```

Inspect a volume:

```bash
docker volume inspect agent-docker_pi-data
```

The actual volume names are prefixed by the Compose project name.

## Git configuration

Configure your Git identity inside the container:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

Git configuration is stored in a persistent Docker volume.

## Lifecycle management

You can manage AgentBox directly through Docker Compose or use the AgentBox CLI helper.

Stop the container:

```bash
docker compose stop
```

Start the container:

```bash
docker compose start
```

Restart the container:

```bash
docker compose restart
```

Remove the container:

```bash
docker compose down
```

Rebuild the image and start:

```bash
docker compose up -d --build
```

Remove everything, including persistent data:

```bash
docker compose down -v
```

**WARNING:** The last command permanently deletes all named volumes, including sessions, authentication credentials and configuration.

Your host workspace is not deleted.

## Updating versions

OpenCode and Pi versions are pinned in the Dockerfile.

To update either application:

1. Change its package version in the Dockerfile.
2. Rebuild the image:

```bash
docker compose up -d --build
```

Alternatively, if you have installed the AgentBox CLI:

```bash
agentbox build
```

Existing workspace files and Docker volumes are preserved.

## Security considerations

- The container runs as a non-root user.
- Application sessions and authentication are stored in Docker-managed volumes.
- Do not commit `.env` files or application credentials.
- Do not mount your Docker socket into the container.
- Only mount workspace directories you trust the agents to access.
- Back up persistent Docker volumes if you want to retain sessions and configuration.

## Project structure

```text
agentbox/
├── Dockerfile
├── compose.yml
├── .dockerignore
├── .gitignore
├── .env.example
├── README.md
├── scripts/
│   └── agentbox
└── workspace/
    └── .gitkeep
```

The `scripts/agentbox` file provides the optional command-line helper for managing the Docker environment.

The workspace directory contains your development projects and is mounted into the container.

Application data is stored separately in Docker-managed named volumes.