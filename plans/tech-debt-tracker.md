## Open Debt

- [ ] Add freshness signals beyond structural checks, such as owner metadata or last-reviewed timestamps for critical docs.
- [ ] Extend the canonical docs set if new high-complexity maintained packages or tool surfaces are added to the repository.
- [ ] Add a dedicated linter for `packages/packages.list` so syntax errors in platform selectors, CLI aliases, and per-manager overrides are caught before install-time parsing.
- [ ] Add a linter that checks `README.md` shell shortcut documentation stays in sync with the exported shortcut functions in the maintained shell profiles.
