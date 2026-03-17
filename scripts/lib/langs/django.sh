#!/usr/bin/env sh
# Django Logic Module

# Purpose: Sets up Django environment for project.
setup_django() {
  local _T0_DJANGO_RT
  _T0_DJANGO_RT=$(date +%s)
  _log_setup "Django" "django"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Web Framework" "Django" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Django: check for manage.py or settings.py with django entry
  if [ -f "manage.py" ] || find . -maxdepth 3 -name "settings.py" -print -quit | grep -q .; then
    :
  elif [ -f "requirements.txt" ] && grep -E -q "^django([=<>! ]|$)" "requirements.txt"; then
    :
  elif [ -f "pyproject.toml" ] && grep -q "django" "pyproject.toml"; then
    :
  else
    log_summary "Web Framework" "Django" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_DJANGO_RT="✅ Detected"
  local _VER_DJANGO
  _VER_DJANGO=$(pip show django 2>/dev/null | grep "^Version:" | awk '{print $2}' || echo "-")

  local _DUR_DJANGO_RT
  _DUR_DJANGO_RT=$(($(date +%s) - _T0_DJANGO_RT))
  log_summary "Web Framework" "Django" "$_STAT_DJANGO_RT" "$_VER_DJANGO" "$_DUR_DJANGO_RT"
}

# Purpose: Checks if Django is relevant.
check_runtime_django() {
  local _TOOL_DESC_DJANGO="${1:-Django}"
  if [ -f "manage.py" ] || find . -maxdepth 3 -name "settings.py" -print -quit | grep -q .; then
    return 0
  fi
  if [ -f "requirements.txt" ] && grep -E -q "^django([=<>! ]|$)" "requirements.txt"; then
    return 0
  fi
  if [ -f "pyproject.toml" ] && grep -q "django" "pyproject.toml"; then
    return 0
  fi
  return 1
}
