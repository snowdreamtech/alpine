# 测试环境文档

## 概述

本目录包含 scripts 重构项目的所有测试文件。测试环境使用 BATS (Bash Automated Testing System) 进行 shell 脚本测试，Node.js 用于 JSON 解析测试，Python 作为后备解析器。

## 目录结构

```
tests/
├── unit/              # 单元测试
│   ├── test_timeout.bats
│   ├── test_json_parser.bats
│   ├── test_process_manager.bats
│   └── test_resolve_bin.bats
├── integration/       # 集成测试
│   ├── test_setup_flow.bats
│   └── test_ci_simulation.bats
├── fixtures/          # 测试数据和 fixtures
│   ├── mock_binaries/
│   └── test_data.json
├── vendor/            # 测试依赖库
│   ├── bats-assert/
│   └── bats-support/
└── README.md          # 本文件
```

## 测试环境要求

### 必需工具

1. **BATS (Bash Automated Testing System)**
   - 版本: >= 1.11.0
   - 安装方式: `mise install npm:bats@latest`
   - 验证: `bats --version`

2. **Node.js**
   - 版本: >= 20.0.0
   - 安装方式: `mise install node@20`
   - 验证: `node --version`

3. **Python**
   - 版本: >= 3.12.0
   - 安装方式: `mise install python@3.12`
   - 验证: `python3 --version`

### 可选工具

- **jq**: JSON 命令行处理器（用于测试 JSON 解析降级）
- **timeout/gtimeout**: 超时命令（用于测试超时机制）

## 当前环境状态

### 已安装工具

✅ **BATS**: 1.13.0

- 路径: `/Users/snowdream/.local/share/mise/installs/npm-bats/1.13.0/bin/bats`
- 状态: 已安装并可用

✅ **Node.js**: v25.8.2

- 路径: `/Users/snowdream/.local/share/mise/installs/node/25.8.2/bin/node`
- 状态: 已安装并可用

✅ **Python**: 3.14.3

- 路径: `/Users/snowdream/.local/share/mise/installs/python/3.14.3/bin/python3`
- 状态: 已安装并可用

### 测试目录结构

✅ **tests/unit/**: 单元测试目录已创建
✅ **tests/integration/**: 集成测试目录已创建
✅ **tests/fixtures/**: 测试数据目录已创建

## 运行测试

### 运行所有测试

```bash
# 运行所有 BATS 测试
bats tests/**/*.bats

# 或使用 make 命令
make test
```

### 运行特定测试套件

```bash
# 运行单元测试
bats tests/unit/*.bats

# 运行集成测试
bats tests/integration/*.bats

# 运行特定测试文件
bats tests/unit/test_timeout.bats
```

### 调试模式

```bash
# 启用详细输出
bats -t tests/unit/test_timeout.bats

# 启用调试模式
DEBUG=1 bats tests/unit/test_timeout.bats
```

## 编写测试

### BATS 测试示例

```bash
#!/usr/bin/env bats

# 加载测试辅助库
load '../vendor/bats-support/load'
load '../vendor/bats-assert/load'

# 设置和清理
setup() {
    # 测试前准备
    export TEST_VAR="value"
}

teardown() {
    # 测试后清理
    unset TEST_VAR
}

# 测试用例
@test "示例测试：验证命令成功" {
    run echo "hello"
    assert_success
    assert_output "hello"
}

@test "示例测试：验证命令失败" {
    run false
    assert_failure
}
```

### Node.js 测试示例

```javascript
// tests/unit/json-parser.test.js
const assert = require("assert");
const { parseJson } = require("../../scripts/lib/json-parser.js");

describe("JSON Parser", () => {
  it("should parse simple JSON", () => {
    const result = parseJson('{"key":"value"}', "key");
    assert.strictEqual(result, "value");
  });
});
```

## 测试覆盖率

### 目标

- 单元测试覆盖率: >= 80%
- 集成测试覆盖率: >= 70%
- 关键路径覆盖率: >= 95%

### 生成覆盖率报告

```bash
# 使用 kcov 生成 shell 脚本覆盖率
kcov --exclude-pattern=/usr coverage/ bats tests/unit/*.bats
```

## 持续集成

测试在 CI 环境中自动运行：

- **GitHub Actions**: `.github/workflows/test.yml`
- **触发条件**: Pull Request, Push to main
- **测试矩阵**: Linux, macOS, Windows

## 故障排查

### BATS 找不到

```bash
# 确保 mise 已安装 BATS
mise install npm:bats@latest

# 或使用 npm 全局安装
npm install -g bats
```

### Node.js 版本不匹配

```bash
# 使用 mise 安装正确版本
mise install node@20

# 或使用 mise 自动安装
mise install
```

### Python 不可用

```bash
# 使用 mise 安装 Python
mise install python@3.12

# 验证安装
python3 --version
```

### 测试超时

```bash
# 增加超时时间
BATS_TEST_TIMEOUT=60 bats tests/unit/test_timeout.bats
```

## 性能基准

### 目标响应时间

- `resolve_bin`（缓存命中）: < 10ms
- `resolve_bin`（mise 查找）: < 100ms
- `resolve_bin`（文件系统搜索）: < 500ms
- JSON 解析（< 1MB）: < 50ms
- 超时触发后清理: < 3 秒

### 运行性能测试

```bash
# 运行性能基准测试
bats tests/unit/test_timeout.bats --filter "performance"
```

## 参考资源

- [BATS 官方文档](https://bats-core.readthedocs.io/)
- [bats-assert 库](https://github.com/bats-core/bats-assert)
- [bats-support 库](https://github.com/bats-core/bats-support)
- [Shell 测试最佳实践](https://github.com/bats-core/bats-core#best-practices)

## 维护者

- 开发团队: Dev Team
- 测试负责人: QA Team
- 最后更新: 2025-04-01
