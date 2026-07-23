# HillStreet Foundation Blueprint v1.0

## Official Organization, Identity & Ecosystem Reference

> **Status:** FINALIZED  
> **Owner:** Charles Tanauan  
> **Organization:** HillStreet  
> **Version:** 1.0  
> **Country:** Philippines

## 1. Organization

### Parent Organization

**HillStreet**

- **Legal business:** HillStreet Information Technology Services
- **Business type:** Sole Proprietorship
- **Headquarters:** Youngfield, Hillside Ville, Tacloban City, Leyte 6500, Philippines
- **Public location:** Tacloban City, Leyte, Philippines

## 2. Brand Identity

### Tagline

> **Building Open Technologies for a Connected Future.**

### Brand Statement

HillStreet is a Philippine technology company that designs, develops, and operates open-source software, artificial intelligence platforms, cloud infrastructure, automation systems, and digital business solutions.

HillStreet is the parent organization of the Open ecosystem.

### Mission

Build secure, open, and scalable technologies that empower developers, businesses, and communities.

### Vision

Become a globally recognized technology company advancing open-source software, AI, automation, and digital infrastructure.

### Core Values

- Open Innovation
- Engineering Excellence
- Integrity
- Security by Design
- Community Collaboration
- Continuous Learning
- Long-Term Thinking
- Sustainability

## 3. Company Personality

### Archetypes

- **The Builder:** Builds reliable platforms.
- **The Innovator:** Creates practical technology for the future.

### Personality

Professional, reliable, developer-first, community-driven, practical, innovative, and transparent.

### Brand Voice

Clear, honest, technical, helpful, professional, and modern.

## 4. Founder Identity

```yaml
name: Charles Tanauan
username: masterkanor
titles:
  - Founder
  - Software Engineer
  - Open Source Developer
organization: HillStreet
country: Philippines
location: Tacloban City, Leyte
roles:
  - Founder
  - Software Engineer
  - Open Source Developer
  - Product Architect
  - Technology Entrepreneur
```

Charles Tanauan is the founder of HillStreet and leads the organization's software engineering, product architecture, open-source strategy, and artificial intelligence initiatives.

### Responsibilities

- Product Vision
- Software Engineering
- AI Engineering
- Platform Architecture
- Business Strategy
- Technology Leadership

## 5. Platform Administrator Identity

```yaml
name: Huxley See
display_name: Huxley Dev
username: huxleydev
title: Platform Administrator
organization: HillStreet
country: Philippines
roles:
  - Platform Administrator
  - DevOps Engineer
  - Infrastructure Engineer
  - Security Administrator
  - Automation Engineer
```

### Responsibilities

- Infrastructure
- DevOps
- CI/CD
- Security
- Cloud
- Automation
- Monitoring
- Internal Platform

## 6. Identity Architecture

```text
Charles Tanauan
Founder · Software Engineer · Open Source Developer
        │
        ▼
     HillStreet
        │
        ▼
   Huxley See
Platform Administrator · Infrastructure · DevOps · Security
```

## 7. Mascot

The official HillStreet mascot is the **Scorpion** 🦂, representing precision, protection, intelligence, determination, adaptability, and resilience.

## 8. Product Ecosystem

```text
HillStreet
├── Open-Connect
├── Open-Command
├── Open-Box
├── Open-Secret
├── Open-Model
└── Open-Worker
```

## 9. Product Catalog

| Product | Based on | Category | Purpose |
|---|---|---|---|
| **Open-Connect** | Open WebUI | AI Workspace Platform | Unified AI workspace for users, teams, agents, models, knowledge, and workflows |
| **Open-Command** | SwarmClaw | Agent Orchestration Platform | Coordinates autonomous agents and distributed execution |
| **Open-Box** | AList | Storage Platform | Unified storage gateway for local and cloud files |
| **Open-Secret** | Fusio | API & Integration Platform | Central gateway for APIs, secrets, authentication, and service integrations |
| **Open-Model** | Ollama | AI Runtime Platform | Runs and manages local AI models |
| **Open-Worker** | Hermes Agent | Autonomous Worker Platform | Executes autonomous work across the ecosystem |

### Open-Connect Responsibilities

AI workspace, chat, knowledge, projects, tasks, models, agents, pipelines, tools, plugins, MCP, and workspaces.

### Open-Command Responsibilities

Swarm coordination, task scheduling, multi-agent planning, execution queue, worker routing, and agent collaboration.

### Open-Box Responsibilities

Storage, documents, media, backup, file sharing, and cloud drives.

### Open-Secret Responsibilities

API gateway, API catalog, API management, authentication, authorization, secret registry, OAuth, webhooks, and service connections.

### Open-Model Responsibilities

LLM runtime, embeddings, model registry, GPU management, model APIs, inference, and quantization.

### Open-Worker Responsibilities

Background jobs, automation, AI workers, scheduled tasks, execution engine, and monitoring.

## 10. Platform Architecture

```text
                              HillStreet
                                   │
       ┌───────────────────────────┼───────────────────────────┐
       │                           │                           │
       ▼                           ▼                           ▼
 Open-Connect               Open-Command                Open-Worker
 AI Workspace            Agent Orchestrator          Execution Engine
       │                           │                           │
       ├──────────────┬────────────┴────────────┬──────────────┤
       ▼              ▼                         ▼              ▼
 Open-Model      Open-Secret               Open-Box      External Services
 AI Runtime      API Gateway               Storage       GitHub, Supabase,
                                                         Cloudflare, etc.
```

## 11. Platform Responsibilities

| Platform | Responsibility |
|---|---|
| Open-Connect | User experience, workspace, chat, projects, knowledge, and AI interaction |
| Open-Command | Planning, orchestration, and multi-agent coordination |
| Open-Worker | Autonomous execution, background jobs, and automation |
| Open-Model | Local model serving, inference, and embeddings |
| Open-Secret | API gateway, authentication, integrations, and secret governance |
| Open-Box | File storage, cloud storage, media, and backups |

## 12. Engineering Principles

- Open Source First
- API First
- AI Native
- Modular Architecture
- Security by Default
- Extensible
- Self-Host Friendly
- Cloud Ready
- Developer Experience First

## 13. GitHub Organization

```yaml
organization: HillStreet
repository_owner: hillstreet-ph
display_name: HillStreet
location: Tacloban City, Leyte, Philippines
description: Building open-source software, AI platforms, automation, cloud infrastructure, and digital solutions for developers, businesses, and communities.
```

## 14. AI Collaboration Profile

```yaml
organization: HillStreet
founder: Charles Tanauan
platform_administrator: Huxley See
country: Philippines
core_technologies:
  - Artificial Intelligence
  - Open Source
  - Software Engineering
  - Cloud Infrastructure
  - Automation
  - DevOps
  - API Platforms
  - Developer Platforms
products:
  - Open-Connect
  - Open-Command
  - Open-Box
  - Open-Secret
  - Open-Model
  - Open-Worker
```

## 15. Naming Decisions

- The ecosystem uses **Open-Model** (based on Ollama), not **Open-Nodel**, because “Open-Model” communicates its purpose clearly.
- **Open-Secret** is the stable API and integration platform identity built on Fusio. Dedicated secret-management components may be incorporated behind that identity as the architecture evolves.

---

Copyright © HillStreet. This blueprint is the canonical organization and ecosystem reference.
