#!/usr/bin/env sh
# Docs Logic Module

# Purpose: Checks for Docusaurus configurations.
install_docusaurus() {
  if ! has_lang_files "" "DOCUSAURUS"; then
    return 0
  fi
  log_summary "Docs" "Docusaurus" "✅ Detected" "-" "0"
}

# Purpose: Checks for MkDocs configurations.
install_mkdocs() {
  if ! has_lang_files "" "MKDOCS"; then
    return 0
  fi
  log_summary "Docs" "MkDocs" "✅ Detected" "-" "0"
}

# Purpose: Checks for Sphinx configurations.
install_sphinx() {
  if ! has_lang_files "" "SPHINX"; then
    return 0
  fi
  log_summary "Docs" "Sphinx" "✅ Detected" "-" "0"
}

# Purpose: Sets up Docs environment.
setup_docs() {
  install_docusaurus
  install_mkdocs
  install_sphinx
  setup_node # To ensure vitepress/docusaurus deps if needed
}
