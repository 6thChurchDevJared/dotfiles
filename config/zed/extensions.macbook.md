# Zed extensions, MacBook Pro only

Zed has no per-machine settings include, and `auto_install_extensions` in the shared `settings.json` applies everywhere it is linked. These five are work-stack only, so they were removed from the shared list rather than installed onto the Mac Mini:

- `helm`
- `kubernetes-snippets`
- `terraform`
- `fastapi-snippets`
- `flask-snippets`

They are already installed on the MacBook Pro. **Omitting an extension from `auto_install_extensions` does not uninstall it** — only setting it to `false` does — so nothing was lost here, and nothing needs doing.

To reinstall them on a rebuilt MacBook, add them through the Zed extensions panel (`cmd+shift+x`), or temporarily add them back to `auto_install_extensions`, let Zed install, then remove the lines again before committing. Do not set them to `false`: that would uninstall them.
