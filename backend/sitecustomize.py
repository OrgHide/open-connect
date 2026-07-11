from __future__ import annotations

import asyncio
import logging
from contextlib import asynccontextmanager

log = logging.getLogger(__name__)


def _patch_open_webui_fastapi_lifespan() -> None:
    try:
        from fastapi import FastAPI
    except Exception:
        return

    original_init = FastAPI.__init__
    if getattr(original_init, '__open_connect_bootstrap_patch__', False):
        return

    def patched_init(self, *args, **kwargs):
        lifespan = kwargs.get('lifespan')
        if lifespan is not None and getattr(lifespan, '__module__', '') == 'open_webui.main':
            @asynccontextmanager
            async def wrapped_lifespan(app):
                async with lifespan(app):
                    try:
                        from open_webui.integrations import init_integrations
                        from open_webui.utils.workspace_bootstrap import bootstrap_workspace_resources

                        init_integrations()
                        if not getattr(app.state, '_open_connect_workspace_bootstrap_started', False):
                            app.state._open_connect_workspace_bootstrap_started = True
                            app.state.workspace_bootstrap_task = asyncio.create_task(bootstrap_workspace_resources())
                    except Exception as exc:
                        log.warning('Open Connect workspace bootstrap setup failed: %s', exc)

                    yield

                    task = getattr(app.state, 'workspace_bootstrap_task', None)
                    if task is not None:
                        task.cancel()

            kwargs['lifespan'] = wrapped_lifespan

        return original_init(self, *args, **kwargs)

    patched_init.__open_connect_bootstrap_patch__ = True
    FastAPI.__init__ = patched_init


_patch_open_webui_fastapi_lifespan()
