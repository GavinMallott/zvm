# zvm.zsh
# echo "ZVM Plugin Loaded..."

# Update function, runs before each prompt
_zig_prompt() {
  if [[ "$ZVM_ACTIVE" == 1 ]]; then
    [[ -n "$ZIG_VERSION" ]] && printf "(zig %s) " "$ZIG_VERSION"
  fi
}
