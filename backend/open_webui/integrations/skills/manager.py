"""
Skill Management System for Open Connect
Integrates skills from SkillsLLM, ClawHub, AgencyAgents, and other platforms
"""

import json
import logging
import os
import subprocess
from typing import Any, Dict, List, Optional, Callable
from dataclasses import dataclass, field
from pathlib import Path
from enum import Enum

log = logging.getLogger(__name__)


class SkillSource(str, Enum):
    """Skill sources"""
    LOCAL = "local"
    SKILLSLLM = "skillsllm"
    CLAWHUB = "clawhub"
    GITHUB = "github"
    NPM = "npm"
    CUSTOM = "custom"


@dataclass
class Skill:
    """Represents a skill"""
    id: str
    name: str
    description: str
    source: SkillSource
    version: str = "1.0.0"
    author: str = ""
    category: str = ""
    tags: List[str] = field(default_factory=list)
    repo_url: str = ""
    local_path: str = ""
    enabled: bool = True
    config: Dict[str, Any] = field(default_factory=dict)
    metadata: Dict[str, Any] = field(default_factory=dict)


class SkillManager:
    """Manages all skills in Open Connect"""
    
    def __init__(self, skills_dir: str = None):
        self.skills_dir = Path(skills_dir or "/app/backend/open_webui/skills")
        self.skills_dir.mkdir(parents=True, exist_ok=True)
        self.skills: Dict[str, Skill] = {}
        self._load_local_skills()
    
    def _load_local_skills(self):
        """Load skills from local directory"""
        for skill_file in self.skills_dir.glob("*.md"):
            try:
                skill = self._parse_skill_file(skill_file)
                if skill:
                    self.skills[skill.id] = skill
                    log.info(f"Loaded skill: {skill.name}")
            except Exception as e:
                log.error(f"Failed to load skill {skill_file}: {e}")
    
    def _parse_skill_file(self, path: Path) -> Optional[Skill]:
        """Parse a skill from markdown file"""
        content = path.read_text()
        
        # Parse frontmatter-like metadata
        metadata = {}
        lines = content.split("\n")
        in_metadata = False
        
        for line in lines:
            if line.strip() == "---":
                in_metadata = not in_metadata
                continue
            if in_metadata and ":" in line:
                key, value = line.split(":", 1)
                metadata[key.strip()] = value.strip()
        
        return Skill(
            id=metadata.get("id", path.stem),
            name=metadata.get("name", path.stem),
            description=metadata.get("description", ""),
            source=SkillSource(metadata.get("source", "local")),
            version=metadata.get("version", "1.0.0"),
            author=metadata.get("author", ""),
            category=metadata.get("category", ""),
            tags=metadata.get("tags", "").split(",") if metadata.get("tags") else [],
            repo_url=metadata.get("repo_url", ""),
            local_path=str(path)
        )
    
    def register_skill(self, skill: Skill):
        """Register a skill"""
        self.skills[skill.id] = skill
        log.info(f"Registered skill: {skill.name}")
    
    def get_skill(self, skill_id: str) -> Optional[Skill]:
        """Get a skill by ID"""
        return self.skills.get(skill_id)
    
    def list_skills(
        self,
        source: SkillSource = None,
        category: str = None,
        enabled_only: bool = True
    ) -> List[Skill]:
        """List skills with optional filters"""
        skills = list(self.skills.values())
        
        if source:
            skills = [s for s in skills if s.source == source]
        
        if category:
            skills = [s for s in skills if s.category == category]
        
        if enabled_only:
            skills = [s for s in skills if s.enabled]
        
        return skills
    
    def enable_skill(self, skill_id: str):
        """Enable a skill"""
        if skill_id in self.skills:
            self.skills[skill_id].enabled = True
            log.info(f"Enabled skill: {skill_id}")
    
    def disable_skill(self, skill_id: str):
        """Disable a skill"""
        if skill_id in self.skills:
            self.skills[skill_id].enabled = False
            log.info(f"Disabled skill: {skill_id}")
    
    async def install_from_github(self, repo_url: str) -> Dict[str, Any]:
        """Install a skill from GitHub"""
        try:
            import subprocess
            
            # Extract repo path
            parts = repo_url.replace("https://github.com/", "").split("/")
            if len(parts) < 2:
                return {"error": "Invalid GitHub URL"}
            
            owner, repo = parts[0], parts[1].replace(".git", "")
            
            # Clone to temp directory
            temp_dir = f"/tmp/skills/{repo}"
            subprocess.run(
                ["git", "clone", "--depth", "1", repo_url, temp_dir],
                check=True,
                capture_output=True
            )
            
            # Find and copy skill files
            skill_files = list(Path(temp_dir).glob("**/*.md"))[:5]
            
            for skill_file in skill_files:
                dest = self.skills_dir / skill_file.name
                subprocess.run(["cp", str(skill_file), str(dest)], check=True)
            
            # Clean up
            subprocess.run(["rm", "-rf", temp_dir], check=True)
            
            # Reload skills
            self._load_local_skills()
            
            return {"status": "success", "skills_installed": len(skill_files)}
        except Exception as e:
            log.error(f"Failed to install skill from GitHub: {e}")
            return {"error": str(e)}
    
    async def install_from_npm(self, package: str) -> Dict[str, Any]:
        """Install a skill from npm"""
        try:
            import subprocess
            
            result = subprocess.run(
                ["npm", "install", "-g", package],
                capture_output=True,
                text=True,
                check=True
            )
            
            return {"status": "success", "output": result.stdout}
        except Exception as e:
            log.error(f"Failed to install skill from npm: {e}")
            return {"error": str(e)}
    
    def get_skill_prompt(self, skill_id: str, context: Dict[str, Any] = None) -> str:
        """Get the prompt for a skill"""
        skill = self.get_skill(skill_id)
        if not skill:
            return ""
        
        try:
            content = Path(skill.local_path).read_text()
            # Remove metadata section
            parts = content.split("---")
            if len(parts) > 2:
                return "\n".join(parts[2:]).strip()
            return content
        except Exception as e:
            log.error(f"Failed to read skill content: {e}")
            return ""


class SkillsLLMConnector:
    """SkillsLLM.com integration"""
    
    SKILLS_REPO = "https://github.com/skillsllm/skills"
    
    def __init__(self, skill_manager: SkillManager):
        self.skill_manager = skill_manager
    
    async def sync_skills(self) -> Dict[str, Any]:
        """Sync skills from SkillsLLM"""
        return await self.skill_manager.install_from_github(self.SKILLS_REPO)
    
    def get_featured_skills(self) -> List[Dict[str, Any]]:
        """Get featured skills from SkillsLLM"""
        return [
            {"id": "hermes-agent", "name": "Hermes Agent", "category": "agent"},
            {"id": "coding", "name": "Coding Assistant", "category": "development"},
            {"id": "research", "name": "Research Agent", "category": "research"},
            {"id": "data-analysis", "name": "Data Analysis", "category": "analytics"},
        ]


class ClawHubConnector:
    """ClawHub.ai integration"""
    
    def __init__(self, api_key: str = None):
        self.api_key = api_key or os.getenv("CLAWHUB_API_KEY")
        self.base_url = "https://api.clawhub.ai/v1"
    
    async def browse_skills(self, category: str = None) -> List[Dict[str, Any]]:
        """Browse available skills"""
        try:
            import aiohttp
            
            params = {}
            if category:
                params["category"] = category
            
            async with aiohttp.ClientSession() as session:
                async with session.get(
                    f"{self.base_url}/skills",
                    params=params,
                    headers={"Authorization": f"Bearer {self.api_key}"}
                ) as resp:
                    data = await resp.json()
                    return data.get("skills", [])
        except Exception as e:
            log.error(f"ClawHub browse error: {e}")
            return []
    
    async def install_skill(self, skill_id: str) -> Dict[str, Any]:
        """Install a skill from ClawHub"""
        try:
            import aiohttp
            
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    f"{self.base_url}/skills/{skill_id}/install",
                    headers={"Authorization": f"Bearer {self.api_key}"}
                ) as resp:
                    return await resp.json()
        except Exception as e:
            log.error(f"ClawHub install error: {e}")
            return {"error": str(e)}


class AgencyAgentsConnector:
    """AgencyAgents.dev integration"""
    
    def __init__(self, api_key: str = None):
        self.api_key = api_key or os.getenv("AGENCYAGENTS_API_KEY")
        self.base_url = "https://api.agencyagents.dev/v1"
    
    async def list_agents(self) -> List[Dict[str, Any]]:
        """List available agents"""
        try:
            import aiohttp
            
            async with aiohttp.ClientSession() as session:
                async with session.get(
                    f"{self.base_url}/agents",
                    headers={"Authorization": f"Bearer {self.api_key}"}
                ) as resp:
                    data = await resp.json()
                    return data.get("agents", [])
        except Exception as e:
            log.error(f"AgencyAgents list error: {e}")
            return []
    
    async def deploy_agent(self, agent_id: str, config: Dict[str, Any]) -> Dict[str, Any]:
        """Deploy an agent"""
        try:
            import aiohttp
            
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    f"{self.base_url}/agents/{agent_id}/deploy",
                    json=config,
                    headers={"Authorization": f"Bearer {self.api_key}"}
                ) as resp:
                    return await resp.json()
        except Exception as e:
            log.error(f"AgencyAgents deploy error: {e}")
            return {"error": str(e)}


# Global skill manager
_skill_manager: Optional[SkillManager] = None


def get_skill_manager() -> SkillManager:
    """Get the global skill manager"""
    global _skill_manager
    if _skill_manager is None:
        _skill_manager = SkillManager()
    return _skill_manager
