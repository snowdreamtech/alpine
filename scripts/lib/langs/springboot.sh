#!/usr/bin/env sh
# Spring Boot Logic Module

# Purpose: Sets up Spring Boot environment for project.
setup_springboot() {
  local _T0_SPRINGBOOT_RT
  _T0_SPRINGBOOT_RT=$(date +%s)
  _log_setup "Spring Boot" "spring-boot"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log_summary "Java Framework" "Spring Boot" "⚖️ Previewed" "-" "0"
    return 0
  fi

  # Detect Spring Boot: check for pom.xml or build.gradle with spring-boot entry
  if [ -f "pom.xml" ] && grep -q "spring-boot" "pom.xml"; then
    :
  elif [ -f "build.gradle" ] && grep -q "spring-boot" "build.gradle"; then
    :
  elif [ -f "build.gradle.kts" ] && grep -q "spring-boot" "build.gradle.kts"; then
    :
  else
    log_summary "Java Framework" "Spring Boot" "⏭️ Skipped" "-" "0"
    return 0
  fi

  local _STAT_SPRINGBOOT_RT="✅ Detected"

  # Heuristic version detection: check pom.xml/gradle properties if possible
  local _VER_SPRINGBOOT="-"
  if [ -f "pom.xml" ]; then
    _VER_SPRINGBOOT=$(grep -m 1 "<spring-boot.version>" pom.xml | sed 's/.*>\(.*\)<.*/\1/' || echo "-")
  fi

  local _DUR_SPRINGBOOT_RT
  _DUR_SPRINGBOOT_RT=$(($(date +%s) - _T0_SPRINGBOOT_RT))
  log_summary "Java Framework" "Spring Boot" "$_STAT_SPRINGBOOT_RT" "$_VER_SPRINGBOOT" "$_DUR_SPRINGBOOT_RT"
}

# Purpose: Checks if Spring Boot is relevant.
check_runtime_springboot() {
  local _TOOL_DESC_SPRINGBOOT="${1:-Spring Boot}"
  if [ -f "pom.xml" ] && grep -q "spring-boot" "pom.xml"; then
    return 0
  fi
  if [ -f "build.gradle" ] && grep -q "spring-boot" "build.gradle"; then
    return 0
  fi
  if [ -f "build.gradle.kts" ] && grep -q "spring-boot" "build.gradle.kts"; then
    return 0
  fi
  return 1
}
