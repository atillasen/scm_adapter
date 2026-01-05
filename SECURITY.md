# Security Policy

## Supported Versions

The following versions of **scm_adapter** are currently supported with security updates:

| Version | Supported |
|--------|-----------|
| main   | ✅ Yes    |
| older releases | ❌ No |

Only the latest version on the `main` branch receives security fixes.

---

## Reporting a Vulnerability

⚠️ **Please do NOT report security vulnerabilities via public GitHub issues.**

If you discover a security vulnerability, please report it responsibly using one of the following methods:

### Preferred options
- **GitHub Security Advisory** (private disclosure)
- **Email to the maintainer** (see GitHub profile)

Please include as much information as possible:
- Description of the vulnerability
- Steps to reproduce
- Affected versions
- Potential impact
- Suggested mitigation (if available)

You can expect an initial response within **7 days**.

---

## Security Best Practices

This project follows these general security principles:

- Minimal privileges when interacting with SCM providers
- Secure handling of tokens and credentials
- No hard-coded secrets in source code
- Clear separation between configuration, logic, and persistence
- Dependencies are kept up to date where possible

---

## Disclosure Policy

- Security issues are investigated promptly
- Fixes are released as soon as reasonably possible
- Security-related changes may be released without prior notice
- Credits will be given to reporters if desired

---

Thank you for helping keep **scm_adapter** secure 🔐
