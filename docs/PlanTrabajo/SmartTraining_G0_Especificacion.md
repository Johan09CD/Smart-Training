# Smart Training — Especificación Técnica
## GRUPO 0: Setup del Proyecto

**Versión:** 1.0  
**Fecha:** Junio 2026  
**Duración estimada:** 3–5 días hábiles  
**Prerequisito:** Ninguno — este es el punto de partida absoluto  
**Resultado al finalizar:** Monorepo funcional con estructura completa, backend NestJS corriendo localmente con Prisma conectado a PostgreSQL, PWA React arrancando en el navegador, y pipeline de CI/CD desplegando automáticamente a staging

---

## Visión general del grupo

El Grupo 0 no produce ninguna funcionalidad de negocio visible para el usuario final. Su único propósito es que el equipo de desarrollo tenga una base sólida, sin fricciones y sin deuda técnica desde el primer día. Todo lo que se construya aquí será la infraestructura sobre la que correrán los 9 grupos restantes.

Un mal setup genera problemas que se multiplican: dependencias que no resuelven, entornos que no coinciden entre desarrolladores, deploys manuales que se olvidan. Este grupo los elimina antes de empezar.

---

## A0.1 — Inicializar el monorepo

### Objetivo
Crear el repositorio con la estructura de Turborepo y pnpm workspaces que sostendrá el proyecto completo. Al terminar esta actividad, cualquier desarrollador que clone el repo puede correr `pnpm install` y tener todo el árbol de dependencias resuelto correctamente.

### Herramientas necesarias
- **Node.js 20 LTS** — verificar con `node -v`
- **pnpm** — instalar globalmente con `npm install -g pnpm` si no está disponible
- **Git** — repositorio ya inicializado en GitHub

### Pasos detallados

#### 1. Crear la estructura de carpetas

Desde la raíz del repositorio vacío, crear manualmente la siguiente estructura:

```
smart-training/
├── apps/
│   ├── web/           ← carpeta vacía por ahora (placeholder)
│   └── api/           ← carpeta vacía por ahora (placeholder)
├── packages/
│   ├── types/
│   ├── validators/
│   └── constants/
├── turbo.json
├── pnpm-workspace.yaml
└── package.json
```

#### 2. Configurar `pnpm-workspace.yaml`

```yaml
packages:
  - "apps/*"
  - "packages/*"
```

#### 3. Configurar `package.json` raíz

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
    "eslint": "^8.0.0"
  },
  "engines": {
    "node": ">=20.0.0",
    "pnpm": ">=8.0.0"
  },
  "packageManager": "pnpm@9.0.0"
}
```

#### 4. Configurar `turbo.json`

```json
{
  "$schema": "https://turbo.build/schema.json",
  "globalDependencies": ["**/.env.*"],
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**", ".next/**", "build/**"]
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

#### 5. Inicializar los paquetes compartidos

Cada carpeta dentro de `packages/` necesita su propio `package.json`. Son paquetes internos que se referenciaran con el protocolo `workspace:*`.

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

#### 6. Crear archivos de entrada mínimos en cada paquete

Para que los paquetes sean importables desde el inicio, crear `src/index.ts` en cada uno con contenido mínimo:

**`packages/types/src/index.ts`:**
```typescript
// Tipos compartidos de Smart Training
// Se irán completando grupo por grupo

export type { };
```

**`packages/validators/src/index.ts`:**
```typescript
// Validaciones Zod compartidas de Smart Training
// Se irán completando grupo por grupo

export { };
```

**`packages/constants/src/index.ts`:**
```typescript
// Constantes y enums compartidos de Smart Training

export const APP_NAME = 'Smart Training';
export const API_VERSION = 'v1';
```

#### 7. Configurar TypeScript base compartido

Crear `tsconfig.base.json` en la raíz:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "CommonJS",
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

#### 8. Configurar Prettier y ESLint a nivel raíz

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
.next
*.generated.ts
prisma/migrations
```

**`.eslintrc.js` (raíz):**
```js
module.exports = {
  root: true,
  extends: ['eslint:recommended'],
  parser: '@typescript-eslint/parser',
  plugins: ['@typescript-eslint'],
  rules: {
    'no-unused-vars': 'off',
    '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
  },
  ignorePatterns: ['dist/', 'build/', 'node_modules/', '*.js'],
};
```

#### 9. Configurar `.gitignore`

```gitignore
# Dependencias
node_modules/
.pnpm-store/

# Builds
dist/
build/
.next/
out/

# Entorno
.env
.env.local
.env.*.local

# Turbo
.turbo/

# IDEs
.vscode/
.idea/
*.swp

# Logs
*.log
npm-debug.log*
pnpm-debug.log*

# OS
.DS_Store
Thumbs.db

# Prisma
prisma/migrations/dev.db
*.db

# Coverage
coverage/
```

#### 10. Ejecutar la instalación inicial

```bash
pnpm install
```

### Verificación de A0.1

```bash
# Debe completar sin errores
pnpm install

# Debe ejecutar el pipeline de Turborepo
pnpm build

# Verificar que los packages son resoluble entre sí
# (se valida implícitamente con el build)
```

**Checklist:**
- [ ] `pnpm install` desde la raíz termina sin errores ni warnings de dependencias faltantes
- [ ] `pnpm build` ejecuta el pipeline de Turborepo y muestra las tareas de los 3 packages
- [ ] Los paquetes `@smart-training/types`, `@smart-training/validators` y `@smart-training/constants` aparecen en el árbol de dependencias resuelto
- [ ] El archivo `.gitignore` excluye correctamente `node_modules/` y `.env`

---

## A0.2 — Inicializar el proyecto NestJS (`apps/api`)

### Objetivo
Tener el backend NestJS corriendo localmente con todos los módulos de dominio creados como esqueletos vacíos, Prisma conectado a una instancia local de PostgreSQL y un archivo `.env.example` que documente cada variable requerida. Al terminar, `GET /` responde con `200 OK` y las migraciones corren sin errores.

### Herramientas necesarias
- **PostgreSQL** corriendo localmente en el puerto 5432 (puede ser Docker: `docker run --name st-postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres:16`)
- **NestJS CLI** instalado globalmente: `npm install -g @nestjs/cli`

### Pasos detallados

#### 1. Crear el proyecto NestJS dentro del monorepo

```bash
cd apps/
nest new api --package-manager pnpm --language ts
cd api/
```

Esto genera la estructura base de NestJS. Luego limpiar los archivos de ejemplo que NestJS genera:
- Eliminar `src/app.controller.spec.ts`
- Simplificar `src/app.controller.ts` para que solo devuelva el health check
- Simplificar `src/app.service.ts`

#### 2. Configurar `apps/api/package.json` para el monorepo

Agregar las dependencias del proyecto al `package.json` generado por NestJS. Las dependencias más importantes a instalar:

```bash
# Desde apps/api/
pnpm add @nestjs/common @nestjs/core @nestjs/platform-express reflect-metadata rxjs
pnpm add @nestjs/config @nestjs/jwt @nestjs/passport
pnpm add passport passport-jwt passport-local
pnpm add @nestjs/schedule
pnpm add @prisma/client
pnpm add bcryptjs
pnpm add class-validator class-transformer
pnpm add @nestjs/throttler
pnpm add ioredis
pnpm add @nestjs/bull bull
pnpm add speakeasy qrcode
pnpm add @sendgrid/mail resend
pnpm add cloudinary multer @types/multer
pnpm add pdfkit exceljs

pnpm add -D prisma @types/passport-jwt @types/passport-local @types/bcryptjs @types/speakeasy @types/qrcode @types/pdfkit
```

Agregar también los paquetes internos del monorepo:
```json
{
  "dependencies": {
    "@smart-training/types": "workspace:*",
    "@smart-training/validators": "workspace:*",
    "@smart-training/constants": "workspace:*"
  }
}
```

#### 3. Configurar `tsconfig.json` en `apps/api`

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

#### 4. Crear los módulos de dominio vacíos

Desde `apps/api/src/`, crear la siguiente estructura de módulos. Cada módulo sigue el patrón estándar de NestJS: un archivo de módulo, un controlador y un servicio, todos vacíos pero correctamente declarados.

```
apps/api/src/
├── main.ts
├── app.module.ts
├── app.controller.ts
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
├── scheduler/
│   ├── scheduler.module.ts
│   └── scheduler.service.ts
└── prisma/
    ├── prisma.module.ts
    └── prisma.service.ts
```

**Contenido de cada módulo vacío (ejemplo para `auth`):**

`auth.module.ts`:
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

`auth.controller.ts`:
```typescript
import { Controller } from '@nestjs/common';

@Controller('auth')
export class AuthController {}
```

`auth.service.ts`:
```typescript
import { Injectable } from '@nestjs/common';

@Injectable()
export class AuthService {}
```

Repetir este patrón para todos los módulos listados.

#### 5. Configurar PrismaModule como módulo global

**`prisma/prisma.service.ts`:**
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

**`prisma/prisma.module.ts`:**
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

#### 6. Configurar `app.module.ts` con todos los módulos registrados

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

#### 7. Health check en `app.controller.ts`

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

#### 8. Configurar `main.ts`

```typescript
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Prefijo global de la API
  app.setGlobalPrefix('v1');

  // Validación automática de DTOs
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,        // elimina campos no declarados en el DTO
      forbidNonWhitelisted: true,
      transform: true,        // convierte tipos automáticamente
    }),
  );

  // CORS — en producción se restringe al dominio de la PWA
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

#### 9. Inicializar Prisma

```bash
# Desde apps/api/
npx prisma init
```

Esto crea `prisma/schema.prisma` y agrega `DATABASE_URL` al `.env`. Editar el `schema.prisma` inicial:

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// Los modelos se agregarán en el Grupo 1 (A1.1)
```

#### 10. Crear el archivo `.env` local y `.env.example`

**`.env` (local, no se sube a Git):**
```env
# Base de datos
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/smart_training_dev"

# JWT
JWT_SECRET="dev-secret-cambiar-en-produccion-min-32-chars"
JWT_EXPIRES_IN="15m"
JWT_REFRESH_SECRET="dev-refresh-secret-cambiar-en-produccion"
JWT_REFRESH_EXPIRES_IN="7d"

# Redis (local)
REDIS_URL="redis://localhost:6379"

# Cloudinary
CLOUDINARY_CLOUD_NAME=""
CLOUDINARY_API_KEY=""
CLOUDINARY_API_SECRET=""

# FCM
FCM_SERVER_KEY=""

# Resend
RESEND_API_KEY=""
RESEND_FROM_EMAIL="noreply@smarttraining.app"

# App
PORT=3000
ALLOWED_ORIGINS="http://localhost:5173"
NODE_ENV="development"
```

**`.env.example` (sí se sube a Git — sin valores reales):**
```env
# Base de datos PostgreSQL
# Formato: postgresql://USER:PASSWORD@HOST:PORT/DATABASE
DATABASE_URL=""

# Autenticación JWT
# Usar strings aleatorios de al menos 32 caracteres en producción
JWT_SECRET=""
JWT_EXPIRES_IN="15m"
JWT_REFRESH_SECRET=""
JWT_REFRESH_EXPIRES_IN="7d"

# Redis (usar Upstash en producción)
# Formato Upstash: rediss://default:TOKEN@host.upstash.io:PORT
REDIS_URL=""

# Cloudinary (obtener en cloudinary.com/console)
CLOUDINARY_CLOUD_NAME=""
CLOUDINARY_API_KEY=""
CLOUDINARY_API_SECRET=""

# Firebase Cloud Messaging (obtener en firebase.google.com/console)
FCM_SERVER_KEY=""

# Resend (obtener en resend.com)
RESEND_API_KEY=""
RESEND_FROM_EMAIL=""

# Servidor
PORT=3000
ALLOWED_ORIGINS=""
NODE_ENV="development"
```

#### 11. Actualizar `apps/api/package.json` con los scripts del monorepo

```json
{
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
}
```

### Verificación de A0.2

```bash
# Desde apps/api/
pnpm dev
# Debe mostrar "Smart Training API corriendo en puerto 3000"

# En otro terminal:
curl http://localhost:3000/v1
# Debe responder: {"ok":true,"service":"Smart Training API",...}

# Migración inicial (schema vacío)
npx prisma migrate dev --name init
# Debe completar sin errores aunque el schema no tenga modelos aún
```

**Checklist:**
- [ ] `pnpm dev` en `apps/api` arranca el servidor en el puerto 3000 sin errores
- [ ] `GET http://localhost:3000/v1` devuelve `{"ok":true,...}` con status `200`
- [ ] `npx prisma migrate dev` corre sin errores contra la BD local
- [ ] El archivo `.env.example` existe y documenta todas las variables con comentarios
- [ ] El archivo `.env` está en `.gitignore` y nunca se sube al repositorio
- [ ] Los 10 módulos aparecen registrados en `AppModule` sin errores de compilación

---

## A0.3 — Inicializar el proyecto React PWA (`apps/web`)

### Objetivo
Tener la PWA React corriendo en el navegador con Tailwind, React Router y el plugin de PWA configurado. La estructura de carpetas por rol debe existir y las rutas base (`/usuario`, `/admin`, `/gerente`) deben renderizar sin errores aunque sean páginas vacías. Lighthouse debe reconocer la app como "instalable".

### Pasos detallados

#### 1. Crear el proyecto con Vite

```bash
cd apps/
pnpm create vite web --template react-ts
cd web/
pnpm install
```

#### 2. Instalar dependencias del frontend

```bash
# Desde apps/web/

# Routing
pnpm add react-router-dom

# HTTP y estado del servidor
pnpm add axios @tanstack/react-query

# Estilos
pnpm add -D tailwindcss postcss autoprefixer
npx tailwindcss init -p

# PWA
pnpm add -D vite-plugin-pwa workbox-window

# Gráficos (para dashboards del gerente)
pnpm add recharts

# Iconos
pnpm add lucide-react

# Paquetes internos del monorepo
# (agregar en package.json manualmente)
```

Agregar al `package.json` de `apps/web`:
```json
{
  "dependencies": {
    "@smart-training/types": "workspace:*",
    "@smart-training/validators": "workspace:*",
    "@smart-training/constants": "workspace:*"
  }
}
```

#### 3. Configurar Tailwind

**`tailwind.config.js`:**
```javascript
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './index.html',
    './src/**/*.{js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        // Paleta de Smart Training — se refinará en el diseño de UI
        primary: {
          50:  '#f0f9ff',
          100: '#e0f2fe',
          500: '#0ea5e9',
          600: '#0284c7',
          700: '#0369a1',
          900: '#0c4a6e',
        },
        surface: {
          DEFAULT: '#0f172a',  // fondo oscuro principal
          card:    '#1e293b',  // tarjetas
          border:  '#334155',  // bordes
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

**`src/index.css`:**
```css
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Import de Inter desde Google Fonts */
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');

:root {
  --color-primary: #0ea5e9;
  --color-surface: #0f172a;
  --color-surface-card: #1e293b;
}

* {
  box-sizing: border-box;
}

body {
  background-color: #0f172a;
  color: #f1f5f9;
  font-family: 'Inter', system-ui, sans-serif;
  -webkit-font-smoothing: antialiased;
}
```

#### 4. Configurar `vite.config.ts` con el plugin PWA

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
      includeAssets: ['favicon.ico', 'apple-touch-icon.png', 'masked-icon.svg'],
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
                maxAgeSeconds: 60 * 60, // 1 hora
              },
              cacheableResponse: {
                statuses: [0, 200],
              },
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

#### 5. Crear los íconos PWA mínimos

Crear la carpeta `public/icons/` y agregar íconos de al menos 192x192 y 512x512 píxeles. Para el setup inicial se pueden usar íconos placeholder. Lo importante es que existan para que Lighthouse los valide.

```
public/
├── favicon.ico
├── apple-touch-icon.png   (180x180)
└── icons/
    ├── icon-192x192.png
    └── icon-512x512.png
```

> Herramienta rápida para generar íconos PWA desde un logo: https://realfavicongenerator.net

#### 6. Crear la estructura de carpetas del frontend

```
apps/web/src/
├── pages/
│   ├── usuario/
│   │   └── index.tsx       ← placeholder
│   ├── admin/
│   │   └── index.tsx       ← placeholder
│   └── gerente/
│       └── index.tsx       ← placeholder
├── components/
│   └── ui/                 ← componentes base reutilizables
├── hooks/
│   └── useAuth.ts          ← hook de autenticación (vacío por ahora)
├── services/
│   └── api.ts              ← cliente Axios base
├── store/
│   └── auth.store.ts       ← estado de autenticación (vacío por ahora)
├── types/                  ← re-exports de @smart-training/types
│   └── index.ts
└── utils/
    └── index.ts
```

**Contenido de los placeholders (`pages/usuario/index.tsx` como ejemplo):**
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

#### 7. Configurar React Router en `main.tsx`

```tsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import './index.css';

// Pages (placeholders por ahora)
import UsuarioPage from './pages/usuario';
import AdminPage from './pages/admin';
import GerentePage from './pages/gerente';

// QueryClient para React Query
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      staleTime: 1000 * 60 * 5, // 5 minutos
    },
  },
});

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          {/* Ruta raíz — redirige a login (se implementa en G1) */}
          <Route path="/" element={<Navigate to="/login" replace />} />
          
          {/* Login placeholder */}
          <Route
            path="/login"
            element={
              <div className="min-h-screen bg-surface flex items-center justify-center">
                <p className="text-white">Login — Grupo 1</p>
              </div>
            }
          />

          {/* Rutas por rol */}
          <Route path="/usuario/*" element={<UsuarioPage />} />
          <Route path="/admin/*" element={<AdminPage />} />
          <Route path="/gerente/*" element={<GerentePage />} />

          {/* 404 */}
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

#### 8. Configurar el cliente Axios base

**`src/services/api.ts`:**
```typescript
import axios from 'axios';

const BASE_URL = import.meta.env.VITE_API_URL || '/v1';

export const apiClient = axios.create({
  baseURL: BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor — agrega el JWT a cada petición
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

// Response interceptor — manejo de errores globales
// El refresh automático del token se implementa en G1 (A1.4)
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
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

#### 9. Crear el archivo `.env` del frontend

**`apps/web/.env`:**
```env
VITE_API_URL=http://localhost:3000/v1
```

**`apps/web/.env.example`:**
```env
# URL base del backend
# En producción: https://api.smarttraining.app/v1
VITE_API_URL=
```

#### 10. Actualizar `package.json` de `apps/web`

```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "lint": "eslint src/ --ext .ts,.tsx"
  }
}
```

### Verificación de A0.3

```bash
# Desde apps/web/
pnpm dev
# Debe abrir http://localhost:5173 sin errores en consola
```

**Checklist:**
- [ ] `pnpm dev` levanta la PWA en `http://localhost:5173` sin errores en la consola del navegador
- [ ] Navegando a `/usuario`, `/admin` y `/gerente` se renderizan los placeholders sin error 404 ni crash
- [ ] Tailwind aplica estilos: el fondo de la página debe ser oscuro (`#0f172a`)
- [ ] En Chrome DevTools → Application → Manifest, el manifiesto PWA aparece correctamente cargado con nombre, íconos y colores
- [ ] Lighthouse (modo PWA) reporta la app como "instalable" — puede mostrar advertencias sobre HTTPS que son normales en localhost

---

## A0.4 — Configurar CI/CD

### Objetivo
Tener un pipeline en GitHub Actions que bloquee merges con código roto y despliegue automáticamente a los entornos de staging en cada push a `main`. Al terminar, el equipo no necesita ejecutar deploys manualmente nunca más.

### Prerequisitos
- Repositorio creado en GitHub
- Cuenta en **Vercel** con el proyecto `smart-training-web` conectado al repo
- Cuenta en **Railway** con el proyecto `smart-training-api` conectado al repo
- Cuenta en **Upstash** con una instancia Redis creada

### Pasos detallados

#### 1. Configurar los secretos en GitHub

En el repositorio de GitHub → Settings → Secrets and variables → Actions, agregar los siguientes **Repository secrets**:

| Secreto | Descripción |
|---|---|
| `VERCEL_TOKEN` | Token de API de Vercel (obtenido en vercel.com/account/tokens) |
| `VERCEL_ORG_ID` | ID de la organización en Vercel |
| `VERCEL_PROJECT_ID` | ID del proyecto web en Vercel |
| `RAILWAY_TOKEN` | Token de Railway (obtenido en railway.app/account/tokens) |
| `DATABASE_URL` | URL de PostgreSQL de staging en Railway |
| `JWT_SECRET` | Secret para JWT de staging (mínimo 32 chars) |
| `JWT_REFRESH_SECRET` | Secret para refresh tokens de staging |
| `REDIS_URL` | URL de Redis de Upstash |
| `CLOUDINARY_CLOUD_NAME` | Nombre del cloud en Cloudinary |
| `CLOUDINARY_API_KEY` | API key de Cloudinary |
| `CLOUDINARY_API_SECRET` | API secret de Cloudinary |
| `RESEND_API_KEY` | API key de Resend |

#### 2. Crear el workflow de PR (lint + build)

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
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup pnpm
        uses: pnpm/action-setup@v3
        with:
          version: 9

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Lint
        run: pnpm lint

      - name: Build packages
        run: pnpm build --filter=@smart-training/types --filter=@smart-training/validators --filter=@smart-training/constants

      - name: Build API
        run: pnpm build --filter=api
        env:
          DATABASE_URL: "postgresql://postgres:postgres@localhost:5432/test"
          JWT_SECRET: "test-secret-32-chars-minimum-here"
          JWT_REFRESH_SECRET: "test-refresh-secret-32-chars-here"

      - name: Build Web
        run: pnpm build --filter=web
        env:
          VITE_API_URL: "https://api.smarttraining.app/v1"
```

#### 3. Crear el workflow de deploy a staging

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
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup pnpm
        uses: pnpm/action-setup@v3
        with:
          version: 9

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Run Prisma migrations
        run: pnpm --filter=api prisma:migrate
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
    needs: deploy-api   # el frontend se despliega después del backend

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup pnpm
        uses: pnpm/action-setup@v3
        with:
          version: 9

      - name: Setup Node.js
        uses: actions/setup-node@v4
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

#### 4. Configurar protección de la rama `main`

En GitHub → Settings → Branches → Add rule para `main`:
- ✅ Require a pull request before merging
- ✅ Require status checks to pass before merging
  - Agregar el check `Lint & Build` del workflow de PR
- ✅ Require branches to be up to date before merging
- ✅ Do not allow bypassing the above settings

#### 5. Configurar variables de entorno en Railway

En el dashboard de Railway → proyecto → servicio API → Variables, agregar todas las variables del `.env.example` con sus valores de staging.

Railway detecta automáticamente que es un proyecto Node.js con NestJS y lo construye con `pnpm build` seguido de `node dist/main`.

#### 6. Configurar variables de entorno en Vercel

En el dashboard de Vercel → proyecto → Settings → Environment Variables, agregar:

| Variable | Entorno | Valor |
|---|---|---|
| `VITE_API_URL` | Production | `https://api.smarttraining.app/v1` |
| `VITE_API_URL` | Preview | `https://api-staging.smarttraining.app/v1` |

Vercel detecta automáticamente que es un proyecto Vite y ejecuta `pnpm build` usando el `vite.config.ts`.

#### 7. Configurar Turborepo Remote Cache (opcional pero recomendado)

Para acelerar los builds en CI, Turborepo puede cachear los resultados en los servidores de Vercel:

```bash
# Autenticar Turborepo con Vercel Remote Cache
npx turbo login
npx turbo link
```

Esto agrega automáticamente la configuración necesaria en `turbo.json`.

### Verificación de A0.4

**Flujo de prueba:**

1. Crear una rama `test/pipeline` desde `main`
2. Hacer un commit con un error de TypeScript intencional (ej. una variable sin tipo)
3. Abrir un PR hacia `main`
4. Verificar que el check de "Lint & Build" falla y bloquea el merge

5. Corregir el error y hacer push
6. Verificar que el check pasa y el PR puede mergearse

7. Mergear el PR a `main`
8. Verificar en GitHub Actions que el workflow de deploy se dispara
9. Verificar en Railway que el backend se actualiza
10. Verificar en Vercel que el frontend se actualiza

**Checklist:**
- [ ] Un PR con error de TypeScript falla el pipeline automáticamente
- [ ] El botón de merge está bloqueado hasta que el check pasa
- [ ] Un merge a `main` dispara el workflow de deploy automáticamente
- [ ] El backend en Railway responde en su URL de staging después del deploy
- [ ] El frontend en Vercel carga en su URL de staging después del deploy
- [ ] Las variables de entorno de producción están en Railway/Vercel y **no** en el código fuente

---

## Estado al finalizar el Grupo 0

Al completar las 4 actividades y sus verificaciones, el equipo tiene:

| Componente | Estado |
|---|---|
| Monorepo Turborepo + pnpm | ✅ Funcional, packages compartidos importables |
| Backend NestJS | ✅ Corriendo en localhost:3000, 10 módulos registrados |
| Prisma + PostgreSQL | ✅ Conectado, primera migración aplicada |
| Frontend React PWA | ✅ Corriendo en localhost:5173, rutas base funcionando |
| Plugin PWA | ✅ Manifiesto válido, app reconocida como instalable |
| CI/CD | ✅ Pipeline bloqueando PRs rotos, deploy automático a staging |
| Variables de entorno | ✅ Documentadas en `.env.example`, nunca en el código |

**El equipo puede comenzar el Grupo 1 (Autenticación) inmediatamente.**

---

## Orden de ejecución recomendado

```
Día 1:  A0.1 — Monorepo (2-3 horas)
         └─► Verificación: pnpm install y pnpm build funcionan

Día 1-2: A0.2 — Backend NestJS (4-6 horas)
         └─► Verificación: servidor corriendo, Prisma conectado

Día 2:   A0.3 — Frontend PWA (3-4 horas)
         └─► Verificación: PWA instalable en Chrome

Día 3-4: A0.4 — CI/CD (4-6 horas, incluye configuración de cuentas)
         └─► Verificación: deploy automático funcionando end-to-end
```

> La actividad A0.4 puede requerir más tiempo si es necesario crear cuentas en Vercel, Railway o Upstash. Se recomienda tener las cuentas listas antes del día 3.

---

*Smart Training · Especificación Técnica G0 · Versión 1.0 · Junio 2026*
