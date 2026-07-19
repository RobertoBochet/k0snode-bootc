module.exports = {
  "extends": [
    "@commitlint/config-conventional"
  ],
  "plugins": [
    "commitlint-plugin-function-rules"
  ],
  "rules": {
    "type-enum": [
      2,
      "always",
      ["chore", "feat", "fix", "docs", "ci", "refactor"]
    ],
    "scope-enum": [0],
    "function-rules/header-max-length": [
      2,
      "always",
      ({type, scope}) => {
        const selectiveScopes = {
          feat: ["k0s", "almalinux", "postgres", "packages", null],
          fix: ["k0s", "pre-commit", "renovate", null],
          docs: ["readme", null],
          ci: [null],
          chore: ["almalinux", "postgres", "pre-commit", "renovate", null],
          refactor: [null]
        }

        if(!selectiveScopes[type]) return [true]
        if(!scope) return [true]

        if (selectiveScopes[type].includes(scope)) return [true]

        return [
          false,
          scope
            ? `Scope "${scope}" is not permitted for type "${type}"`
            : `A scope is required for type "${type}"`
        ]
      }
    ]
  }
}
