"""Railway startup shim.

Avoid blocking Railway readiness on expensive dependency and RAG model bootstrap.
"""

from __future__ import annotations

import asyncio
import logging

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

try:
    import open_webui.routers.retrieval as retrieval_module
except Exception as exc:  # pragma: no cover - best effort startup shim
    log.debug("sitecustomize could not import open_webui.routers.retrieval: %s", exc)
else:
    if getattr(retrieval_module, "get_ef", None) is not None:

        def _get_ef(*args, **kwargs):
            return None

        retrieval_module.get_ef = _get_ef
        log.info("Patched open_webui.routers.retrieval.get_ef to skip eager SentenceTransformer loading")

    if getattr(retrieval_module, "get_rf", None) is not None:

        def _get_rf(*args, **kwargs):
            return None

        retrieval_module.get_rf = _get_rf
        log.info("Patched open_webui.routers.retrieval.get_rf to skip eager reranker loading")
