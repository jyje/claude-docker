# Contributing Guidelines

Thank you for your interest in contributing to our project! 👍

## How to Contribute

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Commit Message Convention

Please use the following commit message format:

```
<type>: <description>
```
or with gitmoji:
```
<gitmoji> <type>: <description>
```

### Types
- `feat`: Add new feature
- `fix`: Fix a bug
- `docs`: Update documentation
- `style`: Changes that do not affect the meaning of the code (formatting, etc)
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `test`: Adding missing tests or correcting existing tests
- `chore`: Changes to build process or auxiliary tools

### Gitmoji (Optional, Not Strictly)
- 🎨 - Improve structure/format of the code
- ✨ - Introduce new features
- 🐛 - Fix a bug
- 📝 - Add or update documentation
- ♻️ - Refactor code
- ✅ - Add, update, or pass tests
- 🔧 - Add or update configuration files
- 🔨 - Add or update development scripts
- 🚀 - Deploy stuff
- 🔖 - Release/Version tags
- 💄 - Add or update the UI and style files
- 🔒 - Fix security issues
- 🔥 - Remove code or files
- 🐳 - Work about Docker
- 👷 - Add or update CI build system
- ⬆️ - Upgrade dependencies
- ⬇️ - Downgrade dependencies
- 🔀 - Merge branches

### Examples:
```
feat: Add user authentication
fix: Fix login validation
...
✨ feat: Add user authentication
🐛 fix: Fix login validation
📝 docs: Update README with new API endpoints
🐳 chore: Update Dockerfile base image
```

## Pull Request Guidelines

- Ensure all tests pass before submitting a PR
- Include a detailed description of changes in your PR
- Keep PRs small and focused on a single change
- Address reviewer feedback and make necessary adjustments

## Development Setup

1. Clone the repository:
    ```bash
    git clone https://github.com/jyje/claude-docker.git
    cd claude-docker
    ```

2. Make sure Docker runtime is installed and running on your system

3. To test your changes locally:
    ```bash
    # Build the image
    docker build -t claude-docker-test .

    # Test the image
    docker run --rm -it claude-docker-test claude --version

    # Test with your API key
    docker run --rm -it \
      -e ANTHROPIC_API_KEY \
      -v $(pwd):/workspace \
      claude-docker-test
    ```

## Testing

- Run existing tests before submitting PR:
    ```bash
    # Build and test locally
    docker build -t claude-docker-test .
    docker run --rm claude-docker-test claude --version
    ```

## Documentation

- Update documentation for new features or changes
- (Optional) Keep translations in sync, see [Translations](#translations)
- Use clear and concise language
- Include code examples where appropriate

## Translations

English is the source of truth. Write or change the English document first, and let translations follow.

| Language | Locale | README | Getting started | Advanced guide |
|----------|--------|--------|-----------------|----------------|
| English | `en` | `readme.md` | `docs/getting-started.md` | `docs/advanced-guide.md` |
| Korean | `ko` | `readme-ko.md` | `docs/getting-started-ko.md` | `docs/advanced-guide-ko.md` |
| Simplified Chinese | `zh-CN` | `readme-zh-CN.md` | `docs/getting-started-zh-CN.md` | `docs/advanced-guide-zh-CN.md` |
| Japanese | `ja` | `readme-ja.md` | `docs/getting-started-ja.md` | `docs/advanced-guide-ja.md` |

### Adding or updating a translation

- Name the file with the locale as a suffix before `.md`, using the codes in the table.
- Translate prose, headings and table descriptions. Leave code blocks, commands, file names, environment variable names and product names as they are.
- Put a marker on the first line of every translated file, naming the English source and the commit it was translated from:
  `<!-- Translated from readme.md at 4892c7a -->`
  Bump the commit when you bring a translation up to date. `git diff <commit> -- readme.md` then shows what changed in English since.
- Links from a translated guide into a README section must use the heading of the translated README, because GitHub builds anchors from the heading text.
- When you add a language, add its switcher entry to the header of every README.

### Keeping translations in sync

Changing an English document does not require updating every translation in the same PR. A translation that lags is fine, and English wins wherever they disagree. The commit in the marker tells reviewers how far behind a translation is.

### AI-assisted translations

Some translations are produced with AI assistance. If yours is, say so in a short note at the top of the file, and mention it in the PR. Review by a native speaker is always welcome.

## Questions or Issues?

- Create a new issue in the Issues tab
- Check existing issues and join the discussion
- For security issues, please email directly instead of creating a public issue

## License

By contributing to this project, you agree that your contributions will be licensed under the project's license. See [license.md](license.md) for details.
