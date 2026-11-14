[![add-on registry](https://img.shields.io/badge/DDEV-Add--on_Registry-blue)](https://addons.ddev.com)
[![tests](https://github.com/helga-agentur/ddev-structurizr/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/helga-agentur/ddev-structurizr/actions/workflows/tests.yml?query=branch%3Amain)
[![last commit](https://img.shields.io/github/last-commit/helga-agentur/ddev-structurizr)](https://github.com/helga-agentur/ddev-structurizr/commits)
[![release](https://img.shields.io/github/v/release/helga-agentur/ddev-structurizr)](https://github.com/helga-agentur/ddev-structurizr/releases/latest)

# DDEV Structurizr

## Overview

This add-on integrates Structurizr into your [DDEV](https://ddev.com/) project.

## Installation

```bash
ddev add-on get helga-agentur/ddev-structurizr
ddev restart
```

After installation, make sure to commit the `.ddev` directory to version control.

## Usage

| Command | Description |
| ------- | ----------- |
| `ddev describe` | View service status and used ports for Structurizr |
| `ddev logs -s structurizr` | Check Structurizr logs |
| `ddev ssh -s structurizr` | Open a shell in the Structurizr container |

## Advanced Customization

To change the Docker image:

```bash
ddev dotenv set .ddev/.env.structurizr --structurizr-docker-image="ddev/ddev-utilities:latest"
ddev add-on get helga-agentur/ddev-structurizr
ddev restart
```

Make sure to commit the `.ddev/.env.structurizr` file to version control.

All customization options (use with caution):

| Variable | Flag | Default |
| -------- | ---- | ------- |
| `STRUCTURIZR_DOCKER_IMAGE` | `--structurizr-docker-image` | `ddev/ddev-utilities:latest` |

## Credits

**Contributed and maintained by [@helga-agentur](https://github.com/helga-agentur)**
