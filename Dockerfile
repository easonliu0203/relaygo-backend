# 使用 Node.js 18 Alpine 作為基礎映像（更小更快）
FROM node:18-alpine

# 設定工作目錄
WORKDIR /app

# 複製 package.json 和 package-lock.json
COPY package*.json ./

# 安裝依賴（包含 devDependencies，因為需要 TypeScript）
RUN npm ci --include=dev

# 複製所有原始碼
COPY . .

# 執行 TypeScript 編譯
RUN npm run build:min

# 暴露 8080 端口
EXPOSE 8080

# 啟動應用程式
CMD ["node", "dist/minimal-server.js"]

