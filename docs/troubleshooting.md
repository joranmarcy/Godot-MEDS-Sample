## Troubleshooting

- **The docks show nothing**: the runtime reporters only send updates when the game is running *with an active debugger connection*.
  - Run the project from the editor (F5) so the editor debugger attaches.
- **Warnings about unknown debugger messages**: enable the Core plugin (or enable Extensions if you want the full UI).
- **`save_to_device` isn’t restoring values**: the variable must be saved to disk (have a non-empty `resource_path`) so it can load/store a stable key.
