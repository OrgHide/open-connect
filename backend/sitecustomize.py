"""Railway startup shim.

Avoid blocking Railway readiness on expensive dependency and RAG model bootstrap.
"""

from __future__ import annotations

import asyncio
import logging
import os

# Keep startup from eagerly downloading the default SentenceTransformer model.
# The app can still use external embeddings/reranking later if configured.
os.environ.setdefault('ENABLE_BASE_MODELS_CACHE', 'false')
os.environ.setdefault('ENABLE_RAG_HYBRID_SEARCH', 'false')
os.environ.setdefault('RAG_EMBEDDING_ENGINE', 'openai')
os.environ.setdefault('RAG_EMBEDDING_MODEL_AUTO_UPDATE', 'false')

log = logging.getLogger(__name__)

try:
    import open_webui.utils.plugin as plugin_module
except Exception as exc:  # pragma: no cover - best effort startup shim
    log.debug("sitecustomize could not import open_webui.utils.plugin: %s", exc)
else:
    original_install = getattr(plugin_module, "install_tool_and_function_dependencies", None)

    if original_install is not None:

        async def _install_tool_and_function_dependencies(*args, **kwargs):
            try:
                asyncio.create_task(original_install(*args, **kwargs))
            except RuntimeError:
                await original_install(*args, **kwargs)
            return None

        plugin_module.install_tool_and_function_dependencies = _install_tool_and_function_dependencies
        log.info("Patched open_webui.utils.plugin.install_tool_and_function_dependencies to run in background")
