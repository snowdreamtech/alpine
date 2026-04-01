# 测试 Fixtures

此目录包含测试所需的数据文件和模拟二进制文件。

## 目录结构

```
fixtures/
├── mock_binaries/     # 模拟的可执行文件
├── test_data.json     # 测试用 JSON 数据
└── README.md          # 本文件
```

## 使用说明

### mock_binaries/

包含用于测试 `resolve_bin` 功能的模拟二进制文件。

### test_data.json

包含用于测试 JSON 解析器的各种 JSON 结构：

- 简单键值对
- 嵌套对象
- 数组
- 复杂结构

## 添加新的 Fixtures

1. 将测试数据文件放在此目录
2. 更新本 README 文档
3. 在测试中引用：`load ../fixtures/test_data.json`
