# 实施计划

- [x] 1. 编写 Bug Condition 探索性测试
  - **Property 1: Bug Condition** - Mise 工具安装后 PATH 未自动管理
  - **关键**: 此测试必须在未修复的代码上失败 - 失败确认 bug 存在
  - **不要在测试失败时尝试修复测试或代码**
  - **注意**: 此测试编码了预期行为 - 在实施后通过时将验证修复
  - **目标**: 展示证明 bug 存在的反例
  - **作用域 PBT 方法**: 对于确定性 bug，将属性作用域限定为具体的失败案例以确保可重现性
  - 测试实施细节来自设计文档中的 Bug Condition
  - 测试断言应匹配设计文档中的 Expected Behavior Properties
  - 在未修复的代码上运行测试
  - **预期结果**: 测试失败（这是正确的 - 证明 bug 存在）
  - 记录发现的反例以理解根本原因
  - 当测试编写、运行并记录失败时标记任务完成
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_

- [x] 2. 编写保持性属性测试（在实施修复之前）
  - **Property 2: Preservation** - 非安装命令和现有工具解析行为
  - **重要**: 遵循观察优先方法论
  - 在未修复的代码上观察非 bug 条件输入的行为
  - 从 Preservation Requirements 编写捕获观察行为模式的基于属性的测试
  - 基于属性的测试生成许多测试用例以提供更强的保证
  - 在未修复的代码上运行测试
  - **预期结果**: 测试通过（这确认了要保持的基线行为）
  - 当测试编写、运行并在未修复的代码上通过时标记任务完成
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8_

- [x] 3. Mise 工具 PATH 管理修复
  - [ ] 3.1 在 `run_mise` 中实施统一 PATH 管理
    - 在 `run_mise install` 成功后（退出码 0）添加 PATH 管理逻辑
    - 检查 `_G_MISE_SHIMS_BASE` 是否已在 PATH 中
    - 如果缺失，使用幂等的 case 语句模式添加到 PATH（避免重复）
    - 仅在 `install` 或 `i` 命令且退出码为 0 时触发
    - _Bug_Condition: isBugCondition(context) where context.command == "run_mise install" AND context.exitCode == 0 AND (\_G_MISE_SHIMS_BASE NOT IN context.PATH)_
    - _Expected_Behavior: 对于任何 `run_mise install <tool>` 成功完成的执行（退出码 0），修复后的函数应自动将 `_G_MISE_SHIMS_BASE` 添加到当前会话的 PATH（如果尚未存在）_
    - _Preservation: 非安装命令（`run_mise list`、`run_mise use` 等）必须产生与原始函数完全相同的行为_
    - _Requirements: 2.1, 2.4, 2.5_

  - [ ] 3.2 在 `run_mise` 中添加 CI PATH 持久化
    - 在添加到会话 PATH 后，检查 `GITHUB_PATH` 是否已设置
    - 如果在 CI 环境中，将 `_G_MISE_SHIMS_BASE` 持久化到 `$GITHUB_PATH` 文件
    - 使用幂等追加（检查是否已存在以避免重复）
    - _Bug_Condition: isBugCondition(context) where is_ci_env AND GITHUB_PATH is set_
    - _Expected_Behavior: 对于任何在 CI 环境中成功完成的 `run_mise install <tool>` 执行（GITHUB_PATH 已设置），修复后的函数应自动将 `_G_MISE_SHIMS_BASE` 持久化到 GITHUB_PATH_
    - _Preservation: 本地开发环境（GITHUB_PATH 未设置）必须继续正常工作_
    - _Requirements: 2.3_

  - [ ] 3.3 重新启用 `refresh_mise_cache` 并添加超时保护
    - 用超时保护版本替换当前禁用的实现
    - 使用 `timeout 5s` 或 `run_with_timeout_robust 5` 包装 `mise ls --json`
    - 使用 `MISE_OFFLINE=1` 防止网络调用
    - 超时或错误时回退到空 JSON `{}`
    - 保持现有的缓存刷新调用位置（在 `run_mise` 成功安装后）
    - _Bug_Condition: isBugCondition(context) where refresh_mise_cache() is called AND mise ls --json hangs_
    - _Expected_Behavior: 对于任何调用 `refresh_mise_cache()` 的执行，修复后的函数应在 5 秒超时保护下执行 `mise ls --json`，成功时返回有效的工具元数据或超时时返回空 JSON `{}`_
    - _Preservation: 现有的工具解析回退层（venv、node_modules、系统 PATH、mise which）必须保持功能_
    - _Requirements: 2.2, 2.6, 3.8_

  - [ ] 3.4 移除 Gitleaks 临时变通方法
    - 在 `scripts/lib/langs/base.sh` 中的 `install_gitleaks()` 函数中
    - 删除手动 PATH 管理代码（添加 mise shims 到 PATH 的 case 语句）
    - 删除 CI 持久化逻辑
    - 仅保留核心 `run_mise install` 调用
    - 保留版本检查和快速路径优化
  - _Preservation: Gitleaks 安装必须继续正常工作（现在通过根修复）_
  - _Requirements: 2.7_

  - [ ] 3.5 验证 Bug Condition 探索性测试现在通过
    - **Property 1: Expected Behavior** - Mise 工具安装后 PATH 自动管理
    - **重要**: 重新运行任务 1 中的相同测试 - 不要编写新测试
    - 任务 1 中的测试编码了预期行为
    - 当此测试通过时，确认满足预期行为
    - 运行任务 1 中的 Bug Condition 探索性测试
    - **预期结果**: 测试通过（确认 bug 已修复）
    - _Requirements: Expected Behavior Properties from design (2.1, 2.2, 2.3, 2.4, 2.5, 2.6)_

  - [ ] 3.6 验证保持性测试仍然通过
    - **Property 2: Preservation** - 非安装命令和现有工具解析行为
    - **重要**: 重新运行任务 2 中的相同测试 - 不要编写新测试
    - 运行任务 2 中的保持性属性测试
    - **预期结果**: 测试通过（确认无回归）
    - 确认修复后所有测试仍然通过（无回归）

- [ ] 4. 检查点 - 确保所有测试通过
  - 确保所有测试通过，如有问题请询问用户。
