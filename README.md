# OIH Bio Tools (MiniMax Code Plugin)

计算生物学工具集合 — 17 个 skill，覆盖结构预测、蛋白设计、分子对接、分子动力学、ADMET 等流程。

> 原插件按 Kimi Code 协议打包（`kimi.plugin.json` + `${KIMI_SKILL_DIR}`），本仓库是 **MiniMax Code 通用 Agent 插件协议** 版本，可以从 Git 仓库直接导入 MiniMax Code。

## 包含的工具

| Skill | 工具 | 用途 |
|---|---|---|
| `oih-overview` | 总览 | 会话开始时加载的工具清单与约定 |
| `oih-alphafold3` | AlphaFold 3 | 蛋白/RNA/DNA/配体复合物结构预测 |
| `oih-bindcraft` | BindCraft | 端到端 binder 设计（无需 PyRosetta） |
| `oih-proteinmpnn` | ProteinMPNN | 基于骨架的序列设计 |
| `oih-pesto` | PeSTo | PPI 界面 / 热点预测 |
| `oih-fpocket` | fpocket | 结合口袋检测 |
| `oih-p2rank` | P2Rank | ML 口袋预测 |
| `oih-gnina` | GNINA | CNN 对接 |
| `oih-vina-gpu` | Vina-GPU | GPU 快速对接 |
| `oih-autodock-gpu` | AutoDock-GPU | AutoDock4 GPU 对接 |
| `oih-diffdock` | DiffDock | 扩散盲对接 |
| `oih-gromacs` | GROMACS | 蛋白 MD（protein-only v1） |
| `oih-esm` | ESM-2 | 蛋白序列嵌入 / 拟困惑度 |
| `oih-chemprop` | Chemprop | ADMET 预测 |
| `oih-discotope3` | DiscoTope 3 | B 细胞表位预测 |
| `oih-igfold` | IgFold | 抗体 / 纳米抗体折叠 |
| `oih-freesasa` | FreeSASA | SASA + ADC 偶联位点（host-side） |

## 安装到 MiniMax Code

### 通过 Git 仓库导入（推荐）

在 MiniMax Code 的 "插件 → 导入插件" 对话框里，粘贴本仓库的 URL（任一公开 Git 仓库即可 — GitHub / Gitee / Codeberg / 自建 Gitea 都行）：

```
https://github.com/<your-org>/oih-bio-tools.git
```

GitHub 仓库子目录导入：在 URL 末尾追加 `?path=<subdir>` 或 GitHub 的 `/tree/main/<subdir>` 形式。

### 运行时依赖

每个工具的 skill 都通过 Docker 容器运行（容器名 `oih-<tool>`）。在本机部署前请准备：

- **Docker Desktop** + NVIDIA GPU 直通
- **`$OIH_HOME`**（默认 `E:/oih`）作为数据 / 模型根，可用环境变量覆盖：
  - `OIH_HOME` / `OIH_DATA` / `OIH_MODELS` / `OIH_COMPOSE`
  - 单个容器名可用 `OIH_CONTAINER_<TOOL>` 覆盖
- **模型权重**（`$OIH_HOME/models/`）按 `E:\oih\DEPLOY.md` §5 部署
- **Docker compose**：`$OIH_HOME/oih-platform/docker-compose.windows.yml`

## 约定

- 数据根：`$OIH_HOME`（默认 `E:/oih`）
- 输入：`$OIH_DATA/inputs/<job>_<tool>/`
- 输出：`$OIH_DATA/outputs/<job>_<tool>/`
- 容器由 `oih_exec` / `oih_ensure_container` 自动拉起

## 协议

- `.minimax-plugin/plugin.json`：V1 manifest
- `skills/<name>/SKILL.md` + `scripts/<name>.sh`：每个工具一个 skill
- `scripts/_common.sh`：共享运行库（容器路径翻译 / GPU 选择 / 状态打印）

## 许可

MIT。