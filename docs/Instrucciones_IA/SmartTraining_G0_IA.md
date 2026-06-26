# Smart Training — G0: Setup del Proyecto
### Instrucciones para Claude Code

---

## Contexto del proyecto

Estás construyendo **Smart Training**, una plataforma de gestión de gimnasio con tres roles: CLIENTE, INSTRUCTOR/ADMIN y GERENTE. Es un monorepo con:
- `apps/web` — PWA React + Vite (frontend)
- `apps/api` — Backend NestJS (backend)
- `packages/` — código TypeScript compartido entre ambas apps

Stack decidido y no negociable: React + Vite · NestJS · PostgreSQL · Prisma · Redis · Tailwind · TypeScript en todo.

---

## Reglas de trabajo para este proyecto

1. **Detente después de cada actividad** (A0.1, A0.2, A0.3, A0.4) y reporta exactamente qué checklist items pasaron y cuáles no antes de continuar.
2. **No instales dependencias que no estén listadas** en este documento. Si crees que falta algo, pregunta antes de agregar.
3. **No crees archivos fuera de la estructura definida.** Si necesitas un archivo que no está en el documento, pregunta.
4. **No inicies la siguiente actividad** si algún ítem del checklist de la anterior falló.
5. **No generes datos de ejemplo ni seeds** en este grupo — eso viene en grupos posteriores.
6. **No implementes lógica de negocio.** Los módulos de NestJS deben quedar como esqueletos vacíos.
7. Si un comando falla, repórtalo con el error completo antes de intentar resolverlo por tu cuenta.

---

## Prerequisitos del entorno (verificar antes de empezar)

```bash
node -v      # debe ser v20.x.x
pnpm -v      # debe estar instalado (npm install -g pnpm si no)
psql --version  # PostgreSQL debe estar corriendo localmente en el puerto 5432
```

Si PostgreSQL no está disponible localmente, levantar con Docker:
```bash
docker run --name st-postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=smart_training_dev \
  -p 5432:5432 \
  -d postgres:16
```

---

## A0.1 — Inicializar el monorepo

### Estructura a crear

```
smart-training/
├── apps/
│   ├── web/.gitkeep
│   └── api/.gitkeep
├── packages/
│   ├── types/
│   │   ├── src/index.ts
│   │   └── package.json
│   ├── validators/
│   │   ├── src/index.ts
│   │   └── package.json
│   └── constants/
│       ├── src/index.ts
│       └── package.json
├── turbo.json
├── pnpm-workspace.yaml
├── package.json
├── tsconfig.base.json
├── .prettierrc
├── .prettierignore
└── .gitignore
```

### Archivos a crear

**`pnpm-workspace.yaml`:**
```yaml
packages:
  - "apps/*"
  - "packages/*"
```

**`package.json` (raíz):**
```json
{
  "name": "smart-training",
  "private": true,
  "scripts": {
    "build": "turbo build",
    "dev": "turbo dev",
    "lint": "turbo lint",
    "test": "turbo test",
    "clean": "turbo clean"
  },
  "devDependencies": {
    "turbo": "latest",
    "typescript": "^5.0.0",
    "@types/node": "^20.0.0",
    "prettier": "^3.0.0",
    "@typescript-eslint/eslint-plugin": "^7.0.0",
    "@typescript-eslint/parser": "^7.0.0",
    "eslint": "^8.0.0"
  },
  "engines": {
    "node": ">=20.0.0",
    "pnpm": ">=8.0.0"
  },
  "packageManager": "pnpm@9.0.0"
}
```

**`turbo.json`:**
```json
{
  "$schema": "https://turbo.build/schema.json",
  "globalDependencies": ["**/.env.*"],
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**", "build/**"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "lint": {
      "dependsOn": ["^build"]
    },
    "test": {
      "dependsOn": ["^build"],
      "outputs": ["coverage/**"]
    },
    "clean": {
      "cache": false
    }
  }
}
```

**`tsconfig.base.json`:**
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022"],
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  }
}
```

**`packages/types/package.json`:**
```json
{
  "name": "@smart-training/types",
  "version": "0.0.1",
  "private": true,
  "main": "./src/index.ts",
  "types": "./src/index.ts",
  "scripts": {
    "build": "tsc --noEmit",
    "lint": "eslint src/"
  },
  "devDependencies": {
    "typescript": "^5.0.0"
  }
}
```

**`packages/types/src/index.ts`:**
```typescript
// Tipos compartidos — se completan en cada grupo
export type {};
```

**`packages/validators/package.json`:**
```json
{
  "name": "@smart-training/validators",
  "version": "0.0.1",
  "private": true,
  "main": "./src/index.ts",
  "types": "./src/index.ts",
  "scripts": {
    "build": "tsc --noEmit",
    "lint": "eslint src/"
  },
  "dependencies": {
    "zod": "^3.22.0"
  },
  "devDependencies": {
    "typescript": "^5.0.0"
  }
}
```

**`packages/validators/src/index.ts`:**
```typescript
// Validaciones Zod — se completan en cada grupo
export {};
```

**`packages/constants/package.json`:**
```json
{
  "name": "@smart-training/constants",
  "version": "0.0.1",
  "private": true,
  "main": "./src/index.ts",
  "types": "./src/index.ts",
  "scripts": {
    "build": "tsc --noEmit",
    "lint": "eslint src/"
  },
  "devDependencies": {
    "typescript": "^5.0.0"
  }
}
```

**`packages/constants/src/index.ts`:**
```typescript
export const APP_NAME = 'Smart Training';
export const API_VERSION = 'v1';
```

**`.prettierrc`:**
```json
{
  "semi": true,
  "singleQuote": true,
  "trailingComma": "all",
  "tabWidth": 2,
  "printWidth": 100
}
```

**`.prettierignore`:**
```
node_modules
dist
build
prisma/migrations
*.generated.ts
```

**`.gitignore`:**
```
node_modules/
.pnpm-store/
dist/
build/
.turbo/
.env
.env.local
.env.*.local
*.log
.DS_Store
coverage/
prisma/dev.db
*.db
```

### Comando a ejecutar

```bash
pnpm install
```

### Checklist de verificación A0.1

- [ ] `pnpm install` termina sin errores
- [ ] `pnpm build` ejecuta sin errores y muestra las 3 tareas de packages
- [ ] Los archivos `packages/types/src/index.ts`, `packages/validators/src/index.ts` y `packages/constants/src/index.ts` existen

**Reportar resultados antes de continuar con A0.2.**

---

## A0.2 — Inicializar el backend NestJS (`apps/api`)

### Decisiones ya tomadas — no preguntar

- El prefijo global de la API es `/v1`
- Validación con `class-validator` y `class-transformer` activada globalmente con `whitelist: true`
- CORS habilitado, origen controlado por variable de entorno
- `PrismaModule` es global (`@Global()`) — no se importa en cada módulo
- El schema de Prisma queda vacío en este grupo — los modelos se agregan en G1
- No se configura Swagger en este grupo

### Comando para crear el proyecto

```bash
cd apps/
npx @nestjs/cli new api --package-manager pnpm --language ts --skip-git
cd api/
```

### Dependencias a instalar (ejecutar desde `apps/api/`)

```bash
# Core NestJS
pnpm add @nestjs/config @nestjs/jwt @nestjs/passport @nestjs/throttler @nestjs/schedule

# Autenticación
pnpm add passport passport-jwt passport-local bcryptjs speakeasy qrcode

# Validación
pnpm add class-validator class-transformer

# Base de datos
pnpm add @prisma/client
pnpm add -D prisma

# Redis / Colas
pnpm add ioredis @nestjs/bull bull

# Servicios externos
pnpm add resend cloudinary multer

# Reportes
pnpm add pdfkit exceljs

# Types
pnpm add -D @types/passport-jwt @types/passport-local @types/bcryptjs @types/speakeasy @types/qrcode @types/multer @types/pdfkit @types/bull
```

Agregar referencias a los paquetes internos en `apps/api/package.json` dentro de `"dependencies"`:
```json
"@smart-training/types": "workspace:*",
"@smart-training/validators": "workspace:*",
"@smart-training/constants": "workspace:*"
```

### Archivos a crear / reemplazar

**`apps/api/tsconfig.json`** (reemplazar el generado por NestJS):
```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "module": "CommonJS",
    "target": "ES2022",
    "outDir": "./dist",
    "rootDir": "./src",
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true,
    "paths": {
      "@smart-training/types": ["../../packages/types/src"],
      "@smart-training/validators": ["../../packages/validators/src"],
      "@smart-training/constants": ["../../packages/constants/src"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### Estructura de `src/` a crear

Eliminar los archivos de ejemplo que genera NestJS (`app.controller.spec.ts`, `app.service.ts`) y crear esta estructura:

```
apps/api/src/
├── main.ts
├── app.module.ts
├── app.controller.ts
├── prisma/
│   ├── prisma.module.ts
│   └── prisma.service.ts
├── auth/
│   ├── auth.module.ts
│   ├── auth.controller.ts
│   └── auth.service.ts
├── usuarios/
│   ├── usuarios.module.ts
│   ├── usuarios.controller.ts
│   └── usuarios.service.ts
├── entrenamiento/
│   ├── entrenamiento.module.ts
│   ├── entrenamiento.controller.ts
│   └── entrenamiento.service.ts
├── maquinas/
│   ├── maquinas.module.ts
│   ├── maquinas.controller.ts
│   └── maquinas.service.ts
├── gimnasio/
│   ├── gimnasio.module.ts
│   ├── gimnasio.controller.ts
│   └── gimnasio.service.ts
├── admin/
│   ├── admin.module.ts
│   ├── admin.controller.ts
│   └── admin.service.ts
├── finanzas/
│   ├── finanzas.module.ts
│   ├── finanzas.controller.ts
│   └── finanzas.service.ts
├── notificaciones/
│   ├── notificaciones.module.ts
│   ├── notificaciones.controller.ts
│   └── notificaciones.service.ts
├── reportes/
│   ├── reportes.module.ts
│   ├── reportes.controller.ts
│   └── reportes.service.ts
└── scheduler/
    ├── scheduler.module.ts
    └── scheduler.service.ts
```

### Contenido de los archivos principales

**`src/main.ts`:**
```typescript
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.setGlobalPrefix('v1');

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  app.enableCors({
    origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:5173'],
    credentials: true,
  });

  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`Smart Training API corriendo en puerto ${port}`);
}

bootstrap();
```

**`src/app.controller.ts`:**
```typescript
import { Controller, Get } from '@nestjs/common';

@Controller()
export class AppController {
  @Get()
  healthCheck() {
    return {
      ok: true,
      service: 'Smart Training API',
      version: '1.0.0',
      timestamp: new Date().toISOString(),
    };
  }
}
```

**`src/app.module.ts`:**
```typescript
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { UsuariosModule } from './usuarios/usuarios.module';
import { EntrenamientoModule } from './entrenamiento/entrenamiento.module';
import { MaquinasModule } from './maquinas/maquinas.module';
import { GimnasioModule } from './gimnasio/gimnasio.module';
import { AdminModule } from './admin/admin.module';
import { FinanzasModule } from './finanzas/finanzas.module';
import { NotificacionesModule } from './notificaciones/notificaciones.module';
import { ReportesModule } from './reportes/reportes.module';
import { SchedulerModule } from './scheduler/scheduler.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    AuthModule,
    UsuariosModule,
    EntrenamientoModule,
    MaquinasModule,
    GimnasioModule,
    AdminModule,
    FinanzasModule,
    NotificacionesModule,
    ReportesModule,
    SchedulerModule,
  ],
  controllers: [AppController],
})
export class AppModule {}
```

**`src/prisma/prisma.service.ts`:**
```typescript
import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  async onModuleInit() {
    await this.$connect();
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
```

**`src/prisma/prisma.module.ts`:**
```typescript
import { Global, Module } from '@nestjs/common';
import { PrismaService } from './prisma.service';

@Global()
@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class PrismaModule {}
```

**Patrón para los 10 módulos de dominio** — aplicar exactamente igual a: `auth`, `usuarios`, `entrenamiento`, `maquinas`, `gimnasio`, `admin`, `finanzas`, `notificaciones`, `reportes`. El módulo `scheduler` no tiene controller (solo module + service).

Ejemplo con `auth` (replicar para los demás cambiando el nombre):

`auth/auth.module.ts`:
```typescript
import { Module } from '@nestjs/common';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';

@Module({
  controllers: [AuthController],
  providers: [AuthService],
  exports: [AuthService],
})
export class AuthModule {}
```

`auth/auth.controller.ts`:
```typescript
import { Controller } from '@nestjs/common';

@Controller('auth')
export class AuthController {}
```

`auth/auth.service.ts`:
```typescript
import { Injectable } from '@nestjs/common';

@Injectable()
export class AuthService {}
```

`scheduler/scheduler.module.ts`:
```typescript
import { Module } from '@nestjs/common';
import { SchedulerService } from './scheduler.service';

@Module({
  providers: [SchedulerService],
})
export class SchedulerModule {}
```

`scheduler/scheduler.service.ts`:
```typescript
import { Injectable } from '@nestjs/common';

@Injectable()
export class SchedulerService {}
```

### Inicializar Prisma

```bash
# Desde apps/api/
npx prisma init
```

Reemplazar el contenido de `prisma/schema.prisma` generado con:
```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// Los modelos se agregan en G1 (A1.1)
```

### Archivos de entorno

**`apps/api/.env`** (crear — nunca subir a Git):
```env
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/smart_training_dev"
JWT_SECRET="dev-secret-minimo-32-caracteres-cambiar"
JWT_EXPIRES_IN="15m"
JWT_REFRESH_SECRET="dev-refresh-secret-minimo-32-caracteres"
JWT_REFRESH_EXPIRES_IN="7d"
REDIS_URL="redis://localhost:6379"
CLOUDINARY_CLOUD_NAME=""
CLOUDINARY_API_KEY=""
CLOUDINARY_API_SECRET=""
FCM_SERVER_KEY=""
RESEND_API_KEY=""
RESEND_FROM_EMAIL="noreply@smarttraining.app"
PORT=3000
ALLOWED_ORIGINS="http://localhost:5173"
NODE_ENV="development"
```

**`apps/api/.env.example`** (crear — sí va a Git):
```env
# Base de datos PostgreSQL
DATABASE_URL=""

# JWT — usar strings aleatorios de mínimo 32 caracteres en producción
JWT_SECRET=""
JWT_EXPIRES_IN="15m"
JWT_REFRESH_SECRET=""
JWT_REFRESH_EXPIRES_IN="7d"

# Redis (Upstash en producción)
REDIS_URL=""

# Cloudinary — cloudinary.com/console
CLOUDINARY_CLOUD_NAME=""
CLOUDINARY_API_KEY=""
CLOUDINARY_API_SECRET=""

# Firebase Cloud Messaging — firebase.google.com/console
FCM_SERVER_KEY=""

# Resend — resend.com
RESEND_API_KEY=""
RESEND_FROM_EMAIL=""

# Servidor
PORT=3000
ALLOWED_ORIGINS=""
NODE_ENV="development"
```

### Scripts en `apps/api/package.json`

Asegurarse de que estos scripts estén presentes:
```json
"scripts": {
  "build": "nest build",
  "dev": "nest start --watch",
  "start": "node dist/main",
  "lint": "eslint src/ --ext .ts",
  "test": "jest",
  "prisma:migrate": "prisma migrate dev",
  "prisma:studio": "prisma studio",
  "prisma:generate": "prisma generate"
}
```

### Comandos a ejecutar

```bash
# Desde apps/api/
pnpm install
npx prisma generate
pnpm dev
```

En otra terminal:
```bash
curl http://localhost:3000/v1
```

### Checklist de verificación A0.2

- [ ] `pnpm dev` arranca sin errores en consola
- [ ] `curl http://localhost:3000/v1` responde `{"ok":true,"service":"Smart Training API",...}`
- [ ] Los 10 módulos están registrados en `AppModule` sin errores de compilación TypeScript
- [ ] `apps/api/.env.example` existe con todas las variables documentadas
- [ ] `apps/api/.env` existe localmente y **no** está en Git (verificar con `git status`)
- [ ] `prisma/schema.prisma` existe con el datasource configurado

**Reportar resultados antes de continuar con A0.3.**

---

## A0.3 — Inicializar el frontend PWA (`apps/web`)

### Decisiones ya tomadas — no preguntar

- Paleta oscura: fondo `#0f172a`, cards `#1e293b`, acento `#0ea5e9`
- Tipografía: Inter desde Google Fonts
- Las rutas `/usuario`, `/admin`, `/gerente` son placeholders — sin lógica de negocio
- El interceptor de refresh del token queda como `// TODO G1` — no implementar ahora
- No instalar librerías de componentes (Shadcn, Radix, etc.) en este grupo
- Los íconos PWA placeholder pueden ser rectángulos de color sólido generados con canvas o cualquier PNG simple — lo importante es que existan en el tamaño correcto

### Comando para crear el proyecto

```bash
cd apps/
pnpm create vite web --template react-ts
cd web/
pnpm install
```

### Dependencias a instalar (desde `apps/web/`)

```bash
pnpm add react-router-dom axios @tanstack/react-query lucide-react recharts
pnpm add -D tailwindcss postcss autoprefixer vite-plugin-pwa workbox-window
npx tailwindcss init -p
```

Agregar a `apps/web/package.json` en `"dependencies"`:
```json
"@smart-training/types": "workspace:*",
"@smart-training/validators": "workspace:*",
"@smart-training/constants": "workspace:*"
```

### Archivos a crear / reemplazar

**`apps/web/vite.config.ts`:**
```typescript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { VitePWA } from 'vite-plugin-pwa';
import path from 'path';

export default defineConfig({
  plugins: [
    react(),
    VitePWA({
      registerType: 'autoUpdate',
      includeAssets: ['favicon.ico', 'apple-touch-icon.png'],
      manifest: {
        name: 'Smart Training',
        short_name: 'SmartTraining',
        description: 'Tu plataforma de gestión de entrenamiento',
        theme_color: '#0f172a',
        background_color: '#0f172a',
        display: 'standalone',
        orientation: 'portrait',
        scope: '/',
        start_url: '/',
        icons: [
          {
            src: '/icons/icon-192x192.png',
            sizes: '192x192',
            type: 'image/png',
          },
          {
            src: '/icons/icon-512x512.png',
            sizes: '512x512',
            type: 'image/png',
            purpose: 'maskable',
          },
        ],
      },
      workbox: {
        globPatterns: ['**/*.{js,css,html,ico,png,svg,woff2}'],
        runtimeCaching: [
          {
            urlPattern: /^https:\/\/api\.smarttraining\.app\/v1\/.*/i,
            handler: 'NetworkFirst',
            options: {
              cacheName: 'api-cache',
              networkTimeoutSeconds: 10,
              expiration: {
                maxEntries: 100,
                maxAgeSeconds: 3600,
              },
              cacheableResponse: { statuses: [0, 200] },
            },
          },
        ],
      },
    }),
  ],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      '@smart-training/types': path.resolve(__dirname, '../../packages/types/src'),
      '@smart-training/validators': path.resolve(__dirname, '../../packages/validators/src'),
      '@smart-training/constants': path.resolve(__dirname, '../../packages/constants/src'),
    },
  },
  server: {
    port: 5173,
    proxy: {
      '/v1': {
        target: 'http://localhost:3000',
        changeOrigin: true,
      },
    },
  },
});
```

**`tailwind.config.js`:**
```javascript
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: {
          50:  '#f0f9ff',
          500: '#0ea5e9',
          600: '#0284c7',
          700: '#0369a1',
        },
        surface: {
          DEFAULT: '#0f172a',
          card:    '#1e293b',
          border:  '#334155',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
};
```

**`src/index.css`** (reemplazar el generado por Vite):
```css
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');

@tailwind base;
@tailwind components;
@tailwind utilities;

* { box-sizing: border-box; }

body {
  background-color: #0f172a;
  color: #f1f5f9;
  font-family: 'Inter', system-ui, sans-serif;
  -webkit-font-smoothing: antialiased;
  margin: 0;
}
```

### Estructura de `src/` a crear

```
apps/web/src/
├── pages/
│   ├── usuario/
│   │   └── index.tsx
│   ├── admin/
│   │   └── index.tsx
│   └── gerente/
│       └── index.tsx
├── components/
│   └── ui/
│       └── .gitkeep
├── hooks/
│   └── useAuth.ts
├── services/
│   └── api.ts
├── store/
│   └── .gitkeep
└── utils/
    └── index.ts
```

**`src/pages/usuario/index.tsx`:**
```tsx
export default function UsuarioPage() {
  return (
    <div className="min-h-screen bg-surface flex items-center justify-center">
      <div className="text-center">
        <h1 className="text-2xl font-bold text-white">Portal del Usuario</h1>
        <p className="text-slate-400 mt-2">En construcción — Grupo 2</p>
      </div>
    </div>
  );
}
```

**`src/pages/admin/index.tsx`:**
```tsx
export default function AdminPage() {
  return (
    <div className="min-h-screen bg-surface flex items-center justify-center">
      <div className="text-center">
        <h1 className="text-2xl font-bold text-white">Panel del Administrador</h1>
        <p className="text-slate-400 mt-2">En construcción — Grupo 5</p>
      </div>
    </div>
  );
}
```

**`src/pages/gerente/index.tsx`:**
```tsx
export default function GerentePage() {
  return (
    <div className="min-h-screen bg-surface flex items-center justify-center">
      <div className="text-center">
        <h1 className="text-2xl font-bold text-white">Panel del Gerente</h1>
        <p className="text-slate-400 mt-2">En construcción — Grupo 6</p>
      </div>
    </div>
  );
}
```

**`src/hooks/useAuth.ts`:**
```typescript
// Se implementa en G1 (A1.4)
export {};
```

**`src/services/api.ts`:**
```typescript
import axios from 'axios';

const BASE_URL = import.meta.env.VITE_API_URL || '/v1';

export const apiClient = axios.create({
  baseURL: BASE_URL,
  headers: { 'Content-Type': 'application/json' },
});

// Agrega el JWT a cada petición
apiClient.interceptors.request.use(
  (config) => {
    const token = sessionStorage.getItem('accessToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error),
);

// Manejo básico de 401 — refresh automático se implementa en G1
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // TODO G1: implementar refresh automático del token
      sessionStorage.removeItem('accessToken');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  },
);

export default apiClient;
```

**`src/utils/index.ts`:**
```typescript
// Utilidades compartidas — se completan en cada grupo
export {};
```

**`src/main.tsx`** (reemplazar el generado por Vite):
```tsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import './index.css';

import UsuarioPage from './pages/usuario';
import AdminPage from './pages/admin';
import GerentePage from './pages/gerente';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: { retry: 1, staleTime: 1000 * 60 * 5 },
  },
});

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Navigate to="/login" replace />} />
          <Route
            path="/login"
            element={
              <div className="min-h-screen bg-surface flex items-center justify-center">
                <p className="text-white text-lg">Login — se implementa en Grupo 1</p>
              </div>
            }
          />
          <Route path="/usuario/*" element={<UsuarioPage />} />
          <Route path="/admin/*" element={<AdminPage />} />
          <Route path="/gerente/*" element={<GerentePage />} />
          <Route
            path="*"
            element={
              <div className="min-h-screen bg-surface flex items-center justify-center">
                <p className="text-white">404 — Página no encontrada</p>
              </div>
            }
          />
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  </React.StrictMode>,
);
```

**`src/App.tsx`:** Eliminar este archivo — el enrutamiento vive en `main.tsx`.

### Íconos PWA

Crear la carpeta `public/icons/` con dos PNGs placeholder (192×192 y 512×512). Pueden ser imágenes sólidas de color `#0ea5e9` con las letras "ST" en blanco. Lo que importa es que existan y tengan el tamaño correcto para que Lighthouse los valide.

### Archivo de entorno

**`apps/web/.env`:**
```env
VITE_API_URL=http://localhost:3000/v1
```

**`apps/web/.env.example`:**
```env
# URL base del backend
# Producción: https://api.smarttraining.app/v1
VITE_API_URL=
```

### Scripts en `apps/web/package.json`

```json
"scripts": {
  "dev": "vite",
  "build": "tsc && vite build",
  "preview": "vite preview",
  "lint": "eslint src/ --ext .ts,.tsx"
}
```

### Comando a ejecutar

```bash
# Desde apps/web/
pnpm install
pnpm dev
```

### Checklist de verificación A0.3

- [ ] `pnpm dev` abre `http://localhost:5173` sin errores en consola del navegador
- [ ] Navegar a `/login`, `/usuario`, `/admin`, `/gerente` renderiza las páginas placeholder sin crash
- [ ] El fondo de la página es oscuro (`#0f172a`) — Tailwind está funcionando
- [ ] En Chrome DevTools → Application → Manifest, el manifiesto aparece con nombre "Smart Training" e íconos
- [ ] No hay errores de TypeScript en ningún archivo

**Reportar resultados antes de continuar con A0.4.**

---

## A0.4 — Configurar CI/CD

### Decisiones ya tomadas — no preguntar

- Dos workflows separados: uno para PR checks, uno para deploy
- El deploy del frontend (`web`) depende de que el deploy del backend (`api`) termine primero
- Las migraciones de Prisma corren automáticamente en el deploy del backend
- No se configura entorno de producción todavía — solo staging

### Prerequisitos

Antes de ejecutar esta actividad, el usuario debe tener:
- Repositorio en GitHub con el código del monorepo
- Cuenta en Vercel con el proyecto conectado al repo
- Cuenta en Railway con el servicio de API conectado al repo
- Los secretos listados abajo configurados en GitHub → Settings → Secrets and variables → Actions

### Secretos requeridos en GitHub

| Nombre del secreto | Cómo obtenerlo |
|---|---|
| `VERCEL_TOKEN` | vercel.com → Account Settings → Tokens |
| `VERCEL_ORG_ID` | vercel.com → Settings → General → Team ID |
| `VERCEL_PROJECT_ID` | vercel.com → proyecto → Settings → General → Project ID |
| `RAILWAY_TOKEN` | railway.app → Account Settings → Tokens |
| `DATABASE_URL` | Railway → proyecto → PostgreSQL → Connect → Connection URL |
| `JWT_SECRET` | Generar: `openssl rand -base64 32` |
| `JWT_REFRESH_SECRET` | Generar: `openssl rand -base64 32` |
| `REDIS_URL` | Upstash → Redis → Connect → URL |

### Archivos a crear

**`.github/workflows/pr-check.yml`:**
```yaml
name: PR Check

on:
  pull_request:
    branches: [main, develop]

jobs:
  lint-and-build:
    name: Lint & Build
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: pnpm/action-setup@v3
        with:
          version: 9

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Lint
        run: pnpm lint

      - name: Build packages
        run: pnpm build --filter=@smart-training/types --filter=@smart-training/validators --filter=@smart-training/constants

      - name: Build API (typecheck)
        run: pnpm --filter=api build
        env:
          DATABASE_URL: "postgresql://postgres:postgres@localhost:5432/test"
          JWT_SECRET: "test-secret-32-chars-minimum-value"
          JWT_REFRESH_SECRET: "test-refresh-32-chars-minimum-ok"
          REDIS_URL: "redis://localhost:6379"
          NODE_ENV: "test"

      - name: Build Web
        run: pnpm --filter=web build
        env:
          VITE_API_URL: "https://api.smarttraining.app/v1"
```

**`.github/workflows/deploy-staging.yml`:**
```yaml
name: Deploy Staging

on:
  push:
    branches: [main]

jobs:
  deploy-api:
    name: Deploy API → Railway
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: pnpm/action-setup@v3
        with:
          version: 9

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Run Prisma migrations
        run: pnpm --filter=api prisma:migrate -- --name auto
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}

      - name: Install Railway CLI
        run: npm install -g @railway/cli

      - name: Deploy to Railway
        run: railway up --service smart-training-api
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}

  deploy-web:
    name: Deploy Web → Vercel
    runs-on: ubuntu-latest
    needs: deploy-api

    steps:
      - uses: actions/checkout@v4

      - uses: pnpm/action-setup@v3
        with:
          version: 9

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Install Vercel CLI
        run: npm install -g vercel

      - name: Deploy to Vercel
        run: vercel --prod --token=${{ secrets.VERCEL_TOKEN }}
        env:
          VERCEL_ORG_ID: ${{ secrets.VERCEL_ORG_ID }}
          VERCEL_PROJECT_ID: ${{ secrets.VERCEL_PROJECT_ID }}
```

### Configurar protección de rama en GitHub

Hacer esto manualmente en el repositorio:

GitHub → Settings → Branches → Add branch protection rule:
- Branch name pattern: `main`
- ✅ Require a pull request before merging
- ✅ Require status checks to pass before merging → agregar `Lint & Build`
- ✅ Require branches to be up to date before merging
- ✅ Do not allow bypassing the above settings

### Variables de entorno en Railway

En Railway → proyecto → servicio API → Variables, agregar exactamente las mismas variables del `.env.example` del backend con sus valores reales de staging.

### Variables de entorno en Vercel

En Vercel → proyecto → Settings → Environment Variables:

| Variable | Entorno | Valor |
|---|---|---|
| `VITE_API_URL` | Production | URL del backend en Railway + `/v1` |
| `VITE_API_URL` | Preview | misma URL |

### Checklist de verificación A0.4

- [ ] Los dos archivos de workflow existen en `.github/workflows/`
- [ ] Crear una rama de prueba, hacer un commit con un error de TypeScript intencional (ej. `const x: string = 123`), abrir PR hacia `main` → el check `Lint & Build` falla y bloquea el merge
- [ ] Corregir el error, hacer push → el check pasa
- [ ] Mergear el PR → el workflow `Deploy Staging` se dispara automáticamente en GitHub Actions
- [ ] El backend responde en su URL de Railway después del deploy
- [ ] El frontend carga en su URL de Vercel después del deploy
- [ ] Ningún secreto o valor de `.env` está visible en el código del repositorio

**Reportar resultados antes de dar el Grupo 0 por completado.**

---

## Resultado esperado al finalizar G0

```
✅ Monorepo funcional — pnpm install y pnpm build corren desde la raíz
✅ Backend NestJS en localhost:3000/v1 con 10 módulos vacíos registrados
✅ Prisma conectado a PostgreSQL local, schema vacío listo para G1
✅ Frontend React PWA en localhost:5173, rutas base sin errores
✅ Manifiesto PWA válido reconocido por Chrome DevTools
✅ CI/CD activo — PRs rotos bloqueados, deploy automático a staging desde main
✅ Variables de entorno documentadas, nunca en el código
```

El Grupo 1 (Autenticación) puede iniciarse una vez que todos los ítems anteriores estén confirmados.

---

*Smart Training · G0 para Claude Code · Junio 2026*
