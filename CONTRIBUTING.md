# Contributing to scm_adapter

Thank you for your interest in contributing to **scm_adapter** 🎉  
All kinds of contributions are welcome – code, documentation, bug reports, ideas, and reviews.

This project focuses on **stability, clean architecture, and long-term maintainability**.
Please read the following guidelines to ensure smooth collaboration.

---

## 1. Ways to contribute

You can contribute by:
- Reporting bugs
- Suggesting features or improvements
- Improving documentation
- Submitting pull requests
- Reviewing issues and pull requests

If you are unsure where to start, feel free to open an issue and ask.

---

## 2. Before you start

Before creating a new issue or pull request:
- Search existing issues and pull requests
- Discuss larger or breaking changes in an issue first
- Keep changes small, focused, and well scoped

---

## 3. Development setup

### Requirements
- Ruby (see `.ruby-version`)
- Bundler
- Git
- Redmine (supported versions are documented in the README)

### Local setup

```bash
git clone https://github.com/atillasen/scm_adapter.git
cd scm_adapter
bundle install
```

To test the plugin locally, install it into your Redmine instance:

```text
redmine/plugins/scm_adapter
```

Restart Redmine after installing or updating the plugin.

---

## 4. Coding standards

Please follow common Ruby and Rails conventions:

- Prefer **readability over cleverness**
- Keep methods small and focused
- Avoid unnecessary dependencies
- Use meaningful class, method, and variable names
- Do not introduce breaking changes without discussion

---

## 5. Architecture principles

The plugin follows a **modular and extensible architecture**:

- Clear separation of concerns:
  - Core logic
  - SCM adapters (GitLab, GitHub, etc.)
  - Background jobs
  - Optional engines (e.g. ADR engine)
- No business logic in controllers
- Avoid tight coupling to Redmine internals
- New SCM providers should follow existing adapter patterns

If you plan architectural changes, please open an issue first.

---

## 6. Testing

- Add tests when introducing new behavior
- Bug fixes should include regression tests
- Prefer unit tests for business logic
- Tests should be deterministic and fast

Please run tests locally before submitting a pull request.

---

## 7. Commit & Pull Request guidelines

### Commit messages

Use clear and descriptive commit messages, for example:

```text
feat: add GitHub webhook support
fix: handle missing project mapping
docs: improve README setup section
refactor: simplify adapter initialization
```

### Pull Requests

- One logical change per pull request
- Reference related issues (e.g. `#42`)
- Clearly describe **what** was changed and **why**
- Keep pull requests small and reviewable

---

## 8. Issue guidelines

When opening an issue, please include:
- Redmine version
- Ruby version
- Plugin version
- Expected behavior
- Actual behavior
- Relevant logs or error messages (if available)

Feature requests should focus on the **use case**, not only on a proposed solution.

---

## 9. Security

Please **do not report security vulnerabilities via public issues**.

If you discover a security issue, contact the maintainer privately:
- GitHub Security Advisory
- Or via email (see repository owner profile)

---

## 10. License

By contributing to this project, you agree that your contributions
will be licensed under the **Apache License 2.0**.

---

Thank you for helping make **scm_adapter** better 🚀
