# Git 基础 · `clone` 到底做了什么

> 面向对象：**前端线搭档**（第一次用 Git 也能看懂）
> 最后更新：2026-10-17
> 配套文档：`docs/ONBOARDING-FRONTEND.md`（上手与开工指南）

---

## 一、`clone` 到底做了什么

```powershell
git clone https://github.com/uxiaoting-code/opc_ai_creator.git
```

这行命令会：

1. 在**你当前所在目录**下，新建一个名为 `opc_ai_creator` 的文件夹；
2. 把 GitHub 上这个仓库的**完整内容 + 全部提交历史**下载进去（包括隐藏的 `.git` 目录）；
3. 自动把远程地址记成 `origin`，并把分支切到 `main`。

**它不是"链接"、不是"共享文件夹"、也不是"快捷方式"** —— 而是一份**完整独立**的本地副本。

举例：如果你在 `D:\code` 下执行，就会得到：

```
D:\code\opc_ai_creator\
    ├── lib\
    ├── server\
    ├── web\
    ├── docs\
    ├── .git\                  ← 隐藏文件夹，提交历史都在这里
    └── AGENTS.md
```

之后你就在 `D:\code\opc_ai_creator` 里改代码。

---

## 二、两台电脑和 GitHub 的关系

```
        GitHub（中心仓库，唯一"真相源"）
          ↑ push              ↓ pull / clone
   后端线电脑 E:\...        前端线电脑 D:\...（或任意位置）
```

- **后端线 push** → 代码上到 GitHub；
- **前端线 clone / pull** → 代码下到自己电脑；
- 两个人**永远不直接访问对方的电脑**。

所以：clone 到哪个盘、哪个文件夹，**完全由你自己决定**（`D:\code`、桌面、`C:\Users\xxx\Documents` 都行）。

只要注意一点：**别 clone 到一个已经有同名文件夹且非空的地方**（Git 会报错）。

---

## 三、两个小细节

### ① 想换个文件夹名

```powershell
git clone https://github.com/uxiaoting-code/opc_ai_creator.git opc-admin
```

最后一个参数就是目标文件夹名，这样会得到 `opc-admin\`。

### ② 代理是"每台电脑各自配"的

别人配好的代理**不会传给你**。如果连不上 GitHub，要在自己电脑上执行：

```powershell
git config --global http.proxy  http://127.0.0.1:7890
git config --global https.proxy http://127.0.0.1:7890
```

（端口按你自己代理软件的来）

---

## 四、`clone` 完第一步该做什么

```powershell
cd opc_ai_creator
git log --oneline -1
```

应该看到：

```
9d82740 feat(admin): P0 地基——ADMIN 鉴权、管理员登录、dev-token 隔离、5 张新表
```

看到这一条，说明拉对了。然后按 `docs/ONBOARDING-FRONTEND.md` 从第 3 节往下走。

---

## 五、几个常见误解

| 误解 | 事实 |
|---|---|
| "clone 完就是共享文件夹了" | ❌ 是两份独立副本。改完必须 `commit` + `push`，对方 `pull` 才能看到 |
| "我在本地改了文件，GitHub 就自动更新了" | ❌ 只有 `add` → `commit` → `push` 三步做完才会更新 |
| "我在本地删了文件，GitHub 上也会没" | ❌ 只有把"删除"也 `commit` + `push` 了，GitHub 上才会消失 |
| "我在 GitHub 网页上改也一样" | ⚠️ 会和本地提交分叉，下次 `push` 必然冲突 —— **别在网页上改** |
| "clone 会把别人的未提交修改也带下来" | ❌ 只同步**已提交并推送**的内容 |

---

## 六、最常用的 7 条命令（小抄）

| 命令 | 作用 | 什么时候用 |
|---|---|---|
| `git clone <url>` | 第一次把仓库下载到本地 | 只做一次 |
| `git pull` | 把 GitHub 上的新提交拉到本地 | **每次开工前** |
| `git status` | 看当前有哪些改动 | 随时 |
| `git add .` | 把改动放进暂存区 | 提交前 |
| `git commit -m "说明"` | 在本地生成一个提交 | 完成一小块后 |
| `git push` | 把本地提交推到 GitHub | **收工前** |
| `git log --oneline -5` | 看最近 5 个提交 | 确认版本时 |

---

## 七、每天的标准流程

```powershell
git pull                                   # ① 开工前先拉
# ……写代码……
git status                                 # ② 看看改了啥
git add .                                  # ③ 放入暂存区
git commit -m "feat: 完成 XXX 组件"         # ④ 本地提交
git push                                   # ⑤ 推到 GitHub
```

> 记住一句话：**`add` / `commit` 只影响你自己的电脑，`push` 才是"发给别人看"。**
