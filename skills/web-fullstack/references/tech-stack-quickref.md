# 技术栈速查

## 前端框架

### React
```bash
# 创建项目
npm create vite@latest my-app -- --template react-ts

# 依赖
npm install react-router-dom axios
```

### Vue
```bash
# 创建项目
npm create vue@latest

# 依赖
npm install vue-router pinia axios
```

## 后端框架

### Node.js + Express
```bash
npm init -y
npm install express cors dotenv
npm install -D typescript @types/node @types/express nodemon
```

### Python + FastAPI
```bash
pip install fastapi uvicorn sqlalchemy pydantic
# 启动: uvicorn main:app --reload
```

### Go + Gin
```bash
go mod init myapp
go get -u github.com/gin-gonic/gin
# 启动: go run main.go
```

### Java + Spring Boot
```xml
<!-- pom.xml 核心依赖 -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
```

## 数据库

### SQLite（开发阶段）轻量推荐
### PostgreSQL（生产环境）全功能推荐
### MySQL（兼容场景）广泛使用

## 项目结构模板

```
my-app/
├── frontend/           # 前端代码
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── api/        # 接口封装
│   │   └── utils/
│   └── package.json
├── backend/            # 后端代码
│   ├── src/
│   │   ├── controllers/
│   │   ├── services/
│   │   ├── models/
│   │   └── routes/
│   ├── requirements.txt / go.mod / pom.xml
│   └── main.py / main.go / Application.java
└── README.md
```
