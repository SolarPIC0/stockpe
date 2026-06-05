# Cloudflare Pages 部署说明

这个工具是纯静态网页，部署到 Cloudflare Pages 时不要上传整个项目根目录。项目里的 `reports/`、`data/`、`docs/` 可能包含研究资料，发布目录只需要包含：

- `index.html`
- `tools/index.html`
- `tools/pe_price_slider.html`
- `_headers`

## 1. 用 GitHub 自动部署

这种方式最适合长期使用：你把代码推到 GitHub，Cloudflare Pages 监听仓库，每次更新后自动部署。

### GitHub 仓库提醒

如果你的 GitHub 仓库是公开仓库，`reports/`、`data/`、`docs/` 里的研究资料也会公开。只是不部署到网站，不等于不出现在 GitHub。若不想公开研究资料，请用私有仓库，或在提交前把这些目录移出仓库。

### Cloudflare Pages 设置

进入 Cloudflare Dashboard：

```text
Workers & Pages -> Create application -> Pages -> Connect to Git
```

选择你的 GitHub 仓库后，构建设置填：

```text
Framework preset: None
Build command: npm run build
Build output directory: cloudflare-pages
Root directory: 留空
```

Cloudflare 会执行 `package.json` 里的：

```json
{
  "scripts": {
    "build": "node scripts/build_cloudflare_pages.mjs"
  }
}
```

这个脚本会生成只包含公开网页文件的 `cloudflare-pages` 目录。

## 2. 本地生成发布目录

在项目根目录运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_cloudflare_pages.ps1
```

生成目录：

```text
cloudflare-pages
```

这句命令的意思是：

- `powershell`：用 PowerShell 执行命令
- `-ExecutionPolicy Bypass`：临时允许本次脚本运行，避免 Windows 拦截本地脚本
- `-File .\scripts\build_cloudflare_pages.ps1`：运行项目里的发布目录生成脚本

它只是本地打包用；GitHub 自动部署时不用手动运行这句，Cloudflare 会执行 `npm run build`。

## 3. 用网页拖拽部署

进入 Cloudflare Dashboard：

```text
Workers & Pages -> Create application -> Pages -> Drag and drop
```

把 `cloudflare-pages` 文件夹拖进去部署。

## 4. 用 Wrangler 部署

如果你装了 Wrangler：

```powershell
npx wrangler pages deploy .\cloudflare-pages --project-name=<你的项目名>
```

第一次运行会要求登录 Cloudflare，并创建或选择 Pages 项目。

## 注意

上线后地址会变成类似：

```text
https://<你的项目名>.pages.dev/
```

不要使用 `http://127.0.0.1:8765/...` 作为线上入口。那只是本机开发地址。
