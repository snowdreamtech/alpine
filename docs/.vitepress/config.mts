import { defineConfig } from 'vitepress'

export default defineConfig({
  lang: 'en-US',
  title: 'Snowdream Tech AI IDE Template',
  description:
    'An enterprise-grade foundational template for multi-AI IDE collaboration, unifying rules, workflows, and configurations across 50+ AI coding assistants.',

  base: '/template/',

  head: [['link', { rel: 'icon', href: '/template/favicon.ico' }]],

  themeConfig: {
    logo: '/logo.svg',

    nav: [
      { text: 'Guide', link: '/guide/introduction' },
      { text: 'Rules', link: '/rules/overview' },
      { text: 'Workflows', link: '/workflows/speckit' },
      { text: 'Reference', link: '/reference/makefile' },
      {
        text: 'Changelog',
        link: 'https://github.com/snowdreamtech/template/blob/main/CHANGELOG.md',
      },
    ],

    sidebar: {
      '/guide/': [
        {
          text: 'Getting Started',
          items: [
            { text: 'Introduction', link: '/guide/introduction' },
            { text: 'Quick Start', link: '/guide/quickstart' },
            { text: 'Project Structure', link: '/guide/structure' },
            { text: 'Configuration', link: '/guide/configuration' },
          ],
        },
        {
          text: 'Developer Experience',
          items: [
            { text: 'DevContainer', link: '/guide/devcontainer' },
            { text: 'Pre-commit Hooks', link: '/guide/precommit' },
            { text: 'VS Code Setup', link: '/guide/vscode' },
            { text: 'AI IDE Integration', link: '/guide/ai-ide' },
          ],
        },
        {
          text: 'CI/CD',
          items: [
            { text: 'GitHub Actions', link: '/guide/ci' },
            { text: 'GoReleaser', link: '/guide/release' },
          ],
        },
      ],
      '/rules/': [
        {
          text: 'Rule System',
          items: [
            { text: 'Overview', link: '/rules/overview' },
            { text: '01 · General', link: '/rules/01-general' },
            { text: '02 · Coding Style', link: '/rules/02-coding-style' },
            { text: '03 · Architecture', link: '/rules/03-architecture' },
            { text: '04 · Security', link: '/rules/04-security' },
            { text: '05 · Dependencies', link: '/rules/05-dependencies' },
            { text: '06 · CI & Testing', link: '/rules/06-ci-testing' },
            { text: '07 · Git', link: '/rules/07-git' },
            { text: '08 · Dev Env', link: '/rules/08-dev-env' },
            { text: '09 · AI Interaction', link: '/rules/09-ai-interaction' },
            { text: '10 · UI/UX', link: '/rules/10-ui-ux' },
            { text: '11 · Deployment', link: '/rules/11-deployment' },
          ],
        },
      ],
      '/workflows/': [
        {
          text: 'SpecKit Workflows',
          items: [
            { text: 'Overview', link: '/workflows/speckit' },
            { text: 'specify', link: '/workflows/specify' },
            { text: 'plan', link: '/workflows/plan' },
            { text: 'tasks', link: '/workflows/tasks' },
            { text: 'implement', link: '/workflows/implement' },
            { text: 'analyze', link: '/workflows/analyze' },
            { text: 'init', link: '/workflows/init' },
          ],
        },
      ],
      '/reference/': [
        {
          text: 'Reference',
          items: [
            { text: 'Makefile Commands', link: '/reference/makefile' },
            { text: 'Supported AI IDEs', link: '/reference/ai-ides' },
            { text: 'Linting Tools', link: '/reference/linters' },
          ],
        },
      ],
    },

    socialLinks: [
      {
        icon: 'github',
        link: 'https://github.com/snowdreamtech/template',
      },
    ],

    footer: {
      message: 'Released under the MIT License.',
      copyright:
        'Copyright © 2026-present SnowdreamTech Inc.',
    },

    editLink: {
      pattern:
        'https://github.com/snowdreamtech/template/edit/main/docs/:path',
      text: 'Edit this page on GitHub',
    },

    search: {
      provider: 'local',
    },
  },
})
